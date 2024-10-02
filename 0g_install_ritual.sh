#!/bin/bash

sudo apt update -y && sudo apt upgrade -y && \
sudo apt install -y curl git jq build-essential gcc unzip wget lz4 openssl \
libssl-dev pkg-config protobuf-compiler clang cmake llvm llvm-dev

cd $HOME && ver="1.22.0" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bash_profile && \
source ~/.bash_profile && go version

echo "Enter MONIKER:"
read -r MONIKER

OG_CHAIN_ID=zgtendermint_16600-2

wget http://167.235.117.176:13124/0gchaind
mkdir -p /home/ritual/go/bin
cp /home/ritual/0gchaind /home/ritual/go/bin
chmod +x /home/ritual/go/bin/0gchaind

min_am=10
max_am=64
random_am=$(shuf -i $min_am-$max_am -n 1)
echo $random_am

/home/ritual/bin/0gchaind config chain-id $OG_CHAIN_ID
/home/ritual/bin/0gchaind config node tcp://localhost:${random_am}657

git clone -b v0.2.5 https://github.com/0glabs/0g-chain.git

/home/ritual/bin/0gchaind init $MONIKER --chain-id $OG_CHAIN_ID
/home/ritual/bin/0gchaind config chain-id $OG_CHAIN_ID
/home/ritual/bin/0gchaind config node tcp://localhost:${random_am}657

wget https://github.com/0glabs/0g-chain/releases/download/v0.2.3/genesis.json -O /home/ritual/.0gchain/config/genesis.json

SEEDS="81987895a11f6689ada254c6b57932ab7ed909b6@54.241.167.190:26656,010fb4de28667725a4fef26cdc7f9452cc34b16d@54.176.175.48:26656,e9b4bc203197b62cc7e6a80a64742e752f4210d5@54.193.250.204:26656,68b9145889e7576b652ca68d985826abd46ad660@18.166.164.232:26656" && \
sed -i.bak -e "s/^seeds *=.*/seeds = \"${SEEDS}\"/" /home/ritual/.0gchain/config/config.toml
peers=$(curl -sS https://lightnode-rpc-0g.grandvalleys.com/net_info | jq -r '.result.peers[] | "\(.node_info.id)@\(.remote_ip):\(.node_info.listen_addr)"' | awk -F ':' '{print $1":"$(NF)}' | paste -sd, -)
echo $peers
sed -i -e "s|^persistent_peers *=.*|persistent_peers = \"$peers\"|" /home/ritual/.0gchain/config/config.toml

sed -i.bak -e "s%:26658%:${random_am}658%g;
s%:26657%:${random_am}657%g;
s%:6060%:${random_am}060%g;
s%:26656%:${random_am}656%g;
s%:26660%:${random_am}660%g" /home/ritual/.0gchain/config/config.toml

sed -i \
   -e "s/laddr = \"tcp:\/\/127.0.0.1:${random_am}657\"/laddr = \"tcp:\/\/0.0.0.0:${random_am}657\"/" \
   /home/ritual/.0gchain/config/config.toml
sed -i \
   -e 's/address = "127.0.0.1:8545"/address = "0.0.0.0:8545"/' \
   -e 's|^api = ".*"|api = "eth,txpool,personal,net,debug,web3"|' \
   -e 's/logs-cap = 10000/logs-cap = 20000/' \
   -e 's/block-range-cap = 10000/block-range-cap = 20000/' \
   /home/ritual/.0gchain/config/app.toml
sed -i \
   -e '/^\[api\]/,/^\[/ s/^address = .*/address = "tcp:\/\/0.0.0.0:1317"/' \
   -e '/^\[api\]/,/^\[/ s/^enable = .*/enable = true/' \
   /home/ritual/.0gchain/config/app.toml
sed -i "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0ua0gi\"/" /home/ritual/.0gchain/config/app.toml
sed -i -e "s/prometheus = false/prometheus = true/" /home/ritual/.0gchain/config/config.toml

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

mkdir -p /home/ritual/.0gchain/cosmovisor/upgrades && \
mkdir -p /home/ritual/.0gchain/cosmovisor/backup

sudo tee /etc/systemd/system/ogd.service > /dev/null <<EOF
[Unit]
Description=0G node
After=network-online.target

[Service]
User=ritual
ExecStart=/home/ritual/go/bin/cosmovisor run start --home /home/ritual/.0gchain
WorkingDirectory=/home/ritual/.0gchain
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
Environment="DAEMON_HOME=/home/ritual/.0gchain"
Environment="DAEMON_NAME=0gchaind"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=true"
Environment="UNSAFE_SKIP_BACKUP=true"

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /home/ritual/.0gchain/cosmovisor/upgrades/v0.3.1/bin/
mkdir -p /home/ritual/.0gchain/cosmovisor/genesis/bin/
mv /home/ritual/0gchaind /home/ritual/.0gchain/cosmovisor/upgrades/v0.3.1/bin/
cp /home/ritual/.0gchain/cosmovisor/upgrades/v0.3.1/bin/0gchaind /home/ritual/.0gchain/cosmovisor/genesis/bin/

chmod +x /home/ritual/.0gchain/cosmovisor/genesis/bin/0gchaind

cp /home/ritual/.0gchain/data/priv_validator_state.json /home/ritual/.0gchain/priv_validator_state.json.backup
rm -rf /home/ritual/.0gchain/data 
curl https://server-5.itrocket.net/testnet/og/og_2024-10-02_1302656_snap.tar.lz4 | lz4 -dc - | tar -xf - -C /home/ritual/.0gchain
mv /home/ritual/.0gchain/priv_validator_state.json.backup /home/ritual/.0gchain/data/priv_validator_state.json

systemctl daemon-reload && \
systemctl enable ogd && \
systemctl restart ogd && \
journalctl -u ogd -fn 100
