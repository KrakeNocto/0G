#!/bin/bash

systemctl stop zgstorage

mv $HOME/0g-storage-node/run/config-testnet.toml $HOME/config-testnet-backup.toml

rm $HOME/0g-storage-node/target/release/zgs_node
wget http://188.40.125.206:31212/zgs_node
mv zgs_node $HOME/0g-storage-node/target/release/
chmod +x /root/0g-storage-node/target/release/zgs_node

mv $HOME/config-testnet-backup.toml $HOME/0g-storage-node/run/config-testnet.toml

sed -i 's|^network_boot_nodes = .*|network_boot_nodes = ["/ip4/54.219.26.22/udp/1234/p2p/16Uiu2HAmTVDGNhkHD98zDnJxQWu3i1FL1aFYeh9wiQTNu4pDCgps","/ip4/52.52.127.117/udp/1234/p2p/16Uiu2HAkzRjxK2gorngB1Xq84qDrT4hSVznYDHj6BkbaE4SGx9oS","/ip4/121.43.181.26/udp/1234/p2p/16Uiu2HAm2k6ua2mGgvZ8rTMV8GhpW71aVzkQWy7D37TTDuLCpgmX"]|g' $HOME/0g-storage-node/run/config-testnet.toml

systemctl restart zgstorage

echo "Storage version is $(/root/0g-storage-node/target/release/zgs_node --version)"

sleep 2

while true; do 
    response=$(curl -s -X POST http://localhost:5678 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')
    logSyncHeight=$(echo $response | jq '.result.logSyncHeight')
    connectedPeers=$(echo $response | jq '.result.connectedPeers')
    echo -e "logSyncHeight: \033[32m$logSyncHeight\033[0m, connectedPeers: \033[34m$connectedPeers\033[0m"
    sleep 5; 
done

tail -f $HOME/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)

rm storage_upd_0.5.1.sh
