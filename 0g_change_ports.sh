#!/bin/bash

sed -i -E '/seeds = .*@og-testnet-seed\.itrocket\.net:47656/!{
  s/47657/26657/g;
  s/47500/3500/g;
  s/47656/26656/g;
  s/47060/26060/g;
  s/47660/26660/g;
  s/47658/26658/g
}' /etc/systemd/system/0gchaind.service /root/.0gchaind/0g-home/0gchaind-home/config/config.toml

sed -i -E '
  s/47545/8545/g;
  s/47546/8546/g;
  s/47551/8551/g;
  s/47303/30303/g
' /etc/systemd/system/0ggeth.service

sed -i -E '
  s/47545/8545/g;
  s/47551/8551/g;
  s/47546/8546/g;
  s/47303/30303/g
' /root/galileo/geth-config.toml

sed -i -E '
  s/47500/3500/g;
  s/47551/8551/g
' /root/.0gchaind/0g-home/0gchaind-home/config/app.toml

sed -i -E "s|^blockchain_rpc_endpoint = \".*\"|blockchain_rpc_endpoint = \"http://$(curl -s 2ip.ru):8545\"|" /root/0g-storage-node/run/config-testnet-turbo.toml

systemctl daemon-reload && systemctl restart 0gchaind 0ggeth zgs zgstorage && journalctl -fu 0gchaind
