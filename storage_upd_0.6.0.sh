#!/bin/bash

systemctl stop zgstorage

rm /home/ritual/0g-storage-node/target/release/zgs_node
http://162.55.94.150:31212/zgs_node

mv zgs_node /home/ritual/0g-storage-node/target/release/
chmod +x /home/ritual/0g-storage-node/target/release/zgs_node

systemctl daemon-reload && systemctl stop zgstorage && systemctl disable zgstorage && systemctl enable zgstorage && systemctl start zgstorage

echo "Storage version is $(/home/ritual/0g-storage-node/target/release/zgs_node --version)"

sleep 2
rm storage_upd_0.6.0.sh

tail -f /home/ritual/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)
