#!/bin/bash

rm stor_upd_0.6.0*

min_am=600
max_am=259200
random_am=$(shuf -i $min_am-$max_am -n 1)

echo "Updating Storage after $random_am seconds"

sleep $random_am

systemctl stop zgstorage

rm $HOME/0g-storage-node/target/release/zgs_node
wget http://162.55.94.150:31212/zgs_node

mv zgs_node $HOME/0g-storage-node/target/release/
chmod +x $HOME/0g-storage-node/target/release/zgs_node

rm -rf 0g-storage-node/run/db/

systemctl daemon-reload && systemctl stop zgstorage && systemctl disable zgstorage && systemctl enable zgstorage && systemctl start zgstorage

echo "Storage version is $($HOME/0g-storage-node/target/release/zgs_node --version)"

sleep 2
rm storage_upd_0.6.0.sh

tail -f $HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)
