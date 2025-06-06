echo "Enter private key:"
read -r KEY

systemctl stop zgstorage && systemctl disable zgstorage

rm config-testnet-turbo*
wget http://195.201.198.8:12385/config-testnet-turbo.toml
wget http://195.201.198.8:12385/zgs_node
cp -r /home/ritual/0g-storage-node/ /root/ && mv config-testnet-turbo.toml /root/0g-storage-node/run/
mv zgs_node /root/0g-storage-node/target/release/zgs_node && chmod +x /root/0g-storage-node/target/release/zgs_node
sed -i "s|^miner_key = \".*\"|miner_key = \"${KEY}\"|" /root/0g-storage-node/run/config-testnet-turbo.toml
sed -i "s|^network_enr_address = \".*\"|network_enr_address = \"$(curl -s 2ip.ru)\"|" /root/0g-storage-node/run/config-testnet-turbo.toml
sed -i 's|--config /home/ritual/0g-storage-node/run/config-testnet-turbo.toml|--config /root/0g-storage-node/run/config-testnet-turbo.toml|' /etc/systemd/system/zgstorage.service
sed -i 's|ExecStart=/home/ritual/0g-storage-node/target/release/zgs_node|ExecStart=/root/0g-storage-node/target/release/zgs_node|' /etc/systemd/system/zgstorage.service
sed -i 's|WorkingDirectory=/home/ritual/0g-storage-node/run|WorkingDirectory=/root/0g-storage-node/run|' /etc/systemd/system/zgstorage.service

systemctl daemon-reload && systemctl enable zgstorage && systemctl start zgstorage

sleep 15

tail -f /root/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)
