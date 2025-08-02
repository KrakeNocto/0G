#!/bin/bash

MONIKER="${1:-${MONIKER}}"
echo "Moniker: $MONIKER"

sudo apt update
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

cd $HOME
wget https://github.com/0glabs/0gchain-NG/releases/download/v1.2.0/galileo-v1.2.0.tar.gz
tar -xzvf galileo-v1.2.0.tar.gz -C $HOME

wget http://195.201.198.8:12385/0gchaind && wget http://195.201.198.8:12385/geth
chmod +x geth
chmod +x 0gchaind

sudo mv geth /usr/local/bin/geth
sudo mv 0gchaind /usr/local/bin/0gchaind

mkdir -p $HOME/.0gchaind
cp -r $HOME/galileo-v1.2.0 $HOME/.0gchaind/galileo
mv $HOME/galileo-v1.2.0 $HOME/galileo
rm galileo-v1.2.0.tar.gz

geth init --datadir $HOME/.0gchaind/galileo/0g-home/geth-home $HOME/.0gchaind/galileo/genesis.json
0gchaind init $MONIKER --home $HOME/.0gchaind/tmp

sed -i -e "s/^moniker *=.*/moniker = \"$MONIKER\"/" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/config.toml
sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"100\"/" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"19\"/" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/app.toml
sed -i "s|laddr = \"tcp://127.0.0.1:26657\"|laddr = \"tcp://0.0.0.0:26657\"|" $HOME/.0gchaind/galileo/0g-home/0gchaind-home/config/config.toml
sed -i 's/HTTPHost = .*/HTTPHost = "0.0.0.0"/' $HOME/.0gchaind/galileo/geth-config.toml

rm -rf /root/.0gchaind/galileo/0g-home/0gchaind-home/data/
rm -rf /root/.0gchaind/galileo/0g-home/geth-home/geth/chaindata/
echo "0G Snapshot Height: $(curl -s https://files.mictonode.com/0g/snapshot/block-height.txt)"
SNAPSHOT_URL="https://files.mictonode.com/0g/snapshot/"
LATEST_COSMOS=$(curl -s $SNAPSHOT_URL | grep -oP '0g_\d{8}-\d{4}_\d+_cosmos\.tar\.lz4' | sort | tail -n 1)
LATEST_GETH=$(curl -s $SNAPSHOT_URL | grep -oP '0g_\d{8}-\d{4}_\d+_geth\.tar\.lz4' | sort | tail -n 1)
if [ -n "$LATEST_COSMOS" ] && [ -n "$LATEST_GETH" ]; then
  COSMOS_URL="${SNAPSHOT_URL}${LATEST_COSMOS}"
  GETH_URL="${SNAPSHOT_URL}${LATEST_GETH}"

  if curl -s --head "$COSMOS_URL" | head -n 1 | grep "200" > /dev/null && \
     curl -s --head "$GETH_URL" | head -n 1 | grep "200" > /dev/null; then
     curl "$COSMOS_URL" | lz4 -dc - | tar -xf - -C /root/.0gchaind/galileo/0g-home/0gchaind-home
     curl "$GETH_URL" | lz4 -dc - | tar -xf - -C /root/.0gchaind/galileo/0g-home/geth-home/geth
  else
    echo "Snapshot URL is not accessible"
  fi
else
  echo "No snapshot found"
fi

mv /root/.0gchaind/tmp/config/node_key.json /root/.0gchaind/galileo/0g-home/0gchaind-home/config/
mv /root/.0gchaind/tmp/config/priv_validator_key.json /root/.0gchaind/galileo/0g-home/0gchaind-home/config/

sudo tee /etc/systemd/system/0gchaind.service > /dev/null <<EOF
[Unit]
Description=0gchaind Node Service
After=network-online.target

[Service]
User=root
Environment=CHAIN_SPEC=devnet
WorkingDirectory=$HOME/.0gchaind/galileo
ExecStart=/usr/local/bin/0gchaind start \
  --chaincfg.chain-spec devnet \
  --home $HOME/.0gchaind/galileo/0g-home/0gchaind-home \
  --chaincfg.kzg.trusted-setup-path=$HOME/.0gchaind/galileo/kzg-trusted-setup.json \
  --chaincfg.engine.jwt-secret-path=$HOME/.0gchaind/galileo/jwt-secret.hex \
  --chaincfg.kzg.implementation=crate-crypto/go-kzg-4844 \
  --chaincfg.engine.rpc-dial-url=http://localhost:8551 \
  --home=$HOME/.0gchaind/galileo/0g-home/0gchaind-home \
  --p2p.seeds 85a9b9a1b7fa0969704db2bc37f7c100855a75d9@8.218.88.60:26656 \
  --p2p.external_address=$(curl https://ipinfo.io/ip):26656
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
User=root
WorkingDirectory=$HOME/.0gchaind/galileo
ExecStart=/usr/local/bin/geth \
  --config $HOME/.0gchaind/galileo/geth-config.toml \
  --datadir $HOME/.0gchaind/galileo/0g-home/geth-home \
  --http.port 8545 \
  --ws.port 8546 \
  --authrpc.port 8551 \
  --bootnodes enode://de7b86d8ac452b1413983049c20eafa2ea0851a3219c2cc12649b971c1677bd83fe24c5331e078471e52a94d95e8cde84cb9d866574fec957124e57ac6056699@8.218.88.60:30303 \
  --port 30303 \
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
