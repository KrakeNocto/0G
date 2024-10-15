#!/bin/bash

systemctl stop zgstorage

rm $HOME/0g-storage-node/target/release/zgs_node
wget http://195.201.197.180:31212/zgs_node

cp $HOME/0g-storage-node/run/config-testnet.toml $HOME/0g-storage-node/run/config-testnet.toml.backup

mv zgs_node $HOME/0g-storage-node/target/release/
chmod +x $HOME/0g-storage-node/target/release/zgs_node

wget http://65.108.10.79:31212/config-testnet-turbo.toml
mv $HOME/config-testnet-turbo.toml $HOME/0g-storage-node/run/

sed -i 's|^network_boot_nodes = .*|network_boot_nodes = ["/ip4/47.251.117.133/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps","/ip4/47.76.61.226/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX"]|g' $HOME/0g-storage-node/run/config-testnet-turbo.toml
sed -ie 's|/root/0g-storage-node/run/[^ ]*|/root/0g-storage-node/run/config-testnet-turbo.toml|' /etc/systemd/system/zgstorage.service
sed -i 's|http://[^:]*:[0-9]*|https://evmrpc-testnet.0g.ai/|' /etc/systemd/system/zgstorage.service

rm -rf $HOME/0g-storage-node/run/db

systemctl daemon-reload && systemctl stop zgstorage && systemctl disable zgstorage && systemctl enable zgstorage && systemctl start zgstorage

echo "Storage version is $($HOME/0g-storage-node/target/release/zgs_node --version)"

sleep 2
rm storage_upd_0.6.0.sh

tail -f $HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)
