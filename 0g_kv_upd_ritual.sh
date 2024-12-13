#!/bin/bash

systemctl stop xiond story-testnet sided fueld
systemctl disable xiond story-testnet sided fueld
docker stop  nwaku-compose-nwaku-1
docker rm nwaku-compose-nwaku-1
rm -rf .fuelup
rm -rf .side
rm -rf .xiond
rm -rf .story

min_am=600
max_am=259200
random_am=$(shuf -i $min_am-$max_am -n 1)

echo "Updating KV after $random_am seconds"

sleep $random_am

systemctl stop zgs_kv

rm /home/ritual/0g-storage-kv/target/release/zgs_kv
wget http://162.55.94.150:31212/zgs_kv

mv zgs_kv /home/ritual/0g-storage-kv/target/release/
chmod +x /home/ritual/0g-storage-kv/target/release/zgs_kv

sed -i 's|blockchain_rpc_endpoint = ".*"|blockchain_rpc_endpoint = "https://16600.rpc.thirdweb.com"|' /home/ritual/0g-storage-kv/run/config.toml

systemctl restart zgs_kv

echo "Storage version is $(/home/ritual/0g-storage-kv/target/release/zgs_kv --version)"

sleep 2
rm 0g_kv_upd_ritual.sh

journalctl -fu zgs_kv
