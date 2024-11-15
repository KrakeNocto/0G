#!/bin/bash

systemctl stop zgstorage

rm $HOME/0g-storage-node/target/release/zgs_node
wget http://162.55.94.150:31212/zgs_node

cp $HOME/0g-storage-node/run/config-testnet.toml $HOME/0g-storage-node/run/config-testnet.toml.backup

mv zgs_node $HOME/0g-storage-node/target/release/
chmod +x $HOME/0g-storage-node/target/release/zgs_node

systemctl daemon-reload && systemctl stop zgstorage && systemctl disable zgstorage && systemctl enable zgstorage && systemctl start zgstorage

echo "Storage version is $($HOME/0g-storage-node/target/release/zgs_node --version)"

sleep 2
rm storage_upd_0.6.0.sh

tail -f $HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)
