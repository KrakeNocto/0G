#!/bin/bash

PRIVATE_KEY_STORAGE="${1:-${PRIVATE_KEY_STORAGE}}"

min_am=600
max_am=18000

host=$(hostname)
ip=$(curl -s --max-time 5 https://2ip.ru | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "0.0.0.0")
mac=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address 2>/dev/null || echo "00:00:00:00:00:00")

id_str="${host}_${ip}_${mac}"
hash=$(echo -n "$id_str" | md5sum | awk '{print $1}')

# offset в пределах от 600 до 2640 секунд (от 10 до 44 минут)
offset=$(( (0x${hash:0:8} % 2041) + 600 ))

random_am=$(shuf -i $min_am-$max_am -n 1)
total_sleep=$((random_am + offset))

echo "Installing Storage after $total_sleep seconds"

sleep $total_sleep

sudo apt-get update
sudo apt-get install -y clang cmake build-essential openssl pkg-config libssl-dev jq git bc

git clone -b v1.1.0 https://github.com/0glabs/0g-storage-node.git

cd $HOME/0g-storage-node
git stash
git fetch --all --tags
git checkout v1.1.0
git submodule update –init

mkdir -p /root/0g-storage-node/target/release
wget http://195.201.198.8:12385/zgs_node
mv zgs_node /root/0g-storage-node/target/release/zgs_node && chmod +x /root/0g-storage-node/target/release/zgs_node
wget http://195.201.198.8:12385/config-testnet-turbo.toml
mv config-testnet-turbo.toml /root/0g-storage-node/run/config-testnet-turbo.toml

sudo tee /etc/systemd/system/zgstorage.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target
[Service]
User=root
WorkingDirectory=/root/0g-storage-node/run
ExecStart=/root/0g-storage-node/target/release/zgs_node --config /root/0g-storage-node/run/config-testnet-turbo.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sed -i "s|^network_enr_address = \".*\"|network_enr_address = \"$(curl https://ipinfo.io/ip)\"|" /root/0g-storage-node/run/config-testnet-turbo.toml
sed -i "s|^blockchain_rpc_endpoint = \".*\"| blockchain_rpc_endpoint = \"${curl -s https://ipinfo.io/ip}:8545\"|" /root/0g-storage-node/run/config-testnet-turbo.toml
sed -i "s|^miner_key = \".*\"|miner_key = \"${PRIVATE_KEY_STORAGE}\"|" /root/0g-storage-node/run/config-testnet-turbo.toml

systemctl daemon-reload && systemctl enable --now zgstorage
