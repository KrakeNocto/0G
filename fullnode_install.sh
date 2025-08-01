#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install curl git wget htop tmux build-essential jq make lz4 gcc unzip -y

cd $HOME && \
ver="1.22.0" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile && \
source ~/.bash_profile && \
go version

MAKE VARIABLE MONIKER HERE!!!!

cd $HOME
wget https://github.com/0glabs/0gchain-NG/releases/download/v1.2.0/galileo-v1.2.0.tar.gz
tar -xzvf galileo-v1.2.0.tar.gz -C $HOME

chmod +x $HOME/galileo/bin/geth
chmod +x $HOME/galileo/bin/0gchaind

sudo cp $HOME/galileo/bin/geth /usr/local/bin/geth
sudo cp $HOME/galileo/bin/0gchaind /usr/local/bin/0gchaind

mkdir -p $HOME/.0gchaind
cp -r $HOME/galileo $HOME/.0gchaind/
geth init --datadir $HOME/.0gchaind/galileo/0g-home/geth-home $HOME/.0gchaind/galileo/genesis.json
0gchaind init $MONIKER --home $HOME/.0gchaind/tmp

sed -i -e "s/^moniker *=.*/moniker = \"$MONIKER\"/" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/config.toml

sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $CONFIG/config.toml

sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/app.toml

sed -i 's/HTTPHost = .*/HTTPHost = "0.0.0.0"/' $HOME/.0gchaind/galileo/geth-config.toml

CONFIG="$HOME/.0gchaind/galileo/0g-home/0gchaind-home/config"
sed -i "s|laddr = \"tcp://127.0.0.1:26657\"|laddr = \"tcp://0.0.0.0:26657\"|" $CONFIG/config.toml

sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=0gchaind Node Service
After=network-online.target

[Service]
User=$USER
Environment=CHAIN_SPEC=devnet
WorkingDirectory=$HOME/.0gchaind/galileo
ExecStart=/usr/local/bin/0gchaind start \
  --chaincfg.chain-spec devnet \
  --home $HOME/.0gchaind/galileo/0g-home/0gchaind-home \
  --chaincfg.kzg.trusted-setup-path=$HOME/.0gchaind/galileo/kzg-trusted-setup.json \
  --chaincfg.engine.jwt-secret-path=$HOME/.0gchaind/galileo/jwt-secret.hex \
  --chaincfg.kzg.implementation=crate-crypto/go-kzg-4844 \
  --chaincfg.engine.rpc-dial-url=http://localhost:${OG_PORT}551 \
  --home=$HOME/.0gchaind/galileo/0g-home/0gchaind-home \
  --p2p.seeds 85a9b9a1b7fa0969704db2bc37f7c100855a75d9@8.218.88.60:26656 \
  --p2p.external_address=$(curl -4 -s ifconfig.me):${OG_PORT}656
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/geth.service > /dev/null <<EOF
[Unit]
Description=0g Geth Node Service
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$HOME/.0gchaind/galileo
ExecStart=/usr/local/bin/geth \
  --config $HOME/.0gchaind/galileo/geth-config.toml \
  --datadir $HOME/.0gchaind/galileo/0g-home/geth-home \
  --http.port ${OG_PORT}545 \
  --ws.port ${OG_PORT}546 \
  --authrpc.port ${OG_PORT}551 \
  --bootnodes enode://de7b86d8ac452b1413983049c20eafa2ea0851a3219c2cc12649b971c1677bd83fe24c5331e078471e52a94d95e8cde84cb9d866574fec957124e57ac6056699@8.218.88.60:30303 \
  --port ${OG_PORT}303 \
  --networkid 16601
Restart=always
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now 0gchaind
sudo systemctl enable --now geth
