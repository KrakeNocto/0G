#!/bin/bash

systemctl stop zgstorage

rm $HOME/0g-storage-node/target/release/zgs_node
wget http://188.40.125.206:31212/zgs_node
wget http://188.40.125.206:31212/config-testnet-turbo.toml

mv zgs_node $HOME/0g-storage-node/target/release/
chmod +x /root/0g-storage-node/target/release/zgs_node

mv $HOME/config-testnet-turbo.toml $HOME/0g-storage-node/run/

sed -i 's|^network_boot_nodes = .*|network_boot_nodes = ["/ip4/54.219.26.22/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps","/ip4/52.52.127.117/udp/1234/p2p/16Uiu2HAkzRjxK2gorngB1Xq84qDrT4hSVznYDHj6BkbaE4SGx9oS","/ip4/121.43.181.26/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX"]|g' $HOME/0g-storage-node/run/config-testnet.toml
sed -ie 's|http://[^ ]*|http://136.243.93.159:8545|' /etc/systemd/system/zgstorage.service
sed -ie 's|/root/0g-storage-node/run/[^ ]*|/root/0g-storage-node/run/config-testnet-turbo.toml|' /etc/systemd/system/zgstorage.service
rm -rf $HOME/0g-storage-node/run/db

systemctl daemon-reload && systemctl stop zgstorage && systemctl disable zgstorage && systemctl enable zgstorage && systemctl start zgstorage

echo "Storage version is $(/root/0g-storage-node/target/release/zgs_node --version)"

sleep 2
rm storage_upd_0.5.1.sh

tail -f $HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)


