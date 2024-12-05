#!/bin/bash

rm stor_upd_0.6.0*

systemctl stop sided && systemctl disable sided
systemctl stop side && systemctl disable side
systemctl stop xiond && systemctl disable xiond

min_am=600
max_am=259200
random_am=$(shuf -i $min_am-$max_am -n 1)

echo "Updating Storage after $random_am seconds"

sleep $random_am

systemctl stop zgstorage

rm /home/ritual/0g-storage-node/target/release/zgs_node
wget http://162.55.94.150:31212/zgs_node

mv zgs_node /home/ritual/0g-storage-node/target/release/
chmod +x /home/ritual/0g-storage-node/target/release/zgs_node

rm -rf /home/ritual/0g-storage-node/run/db/

systemctl daemon-reload && systemctl stop zgstorage && systemctl disable zgstorage && systemctl enable zgstorage && systemctl start zgstorage

echo "Storage version is $(/home/ritual/0g-storage-node/target/release/zgs_node --version)"

sleep 2
rm 0g_upd_ritual.sh

tail -f /home/ritual/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)
