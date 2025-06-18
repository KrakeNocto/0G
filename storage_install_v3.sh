echo "Enter Private Key:"
read -r PRIVATE_KEY
echo "Enter RPC:"
read -r RPC

ufw --force default allow incoming && \
ufw --force enable && \
ufw allow 22 && \
ufw allow 80 && \
ufw allow 443 && \
ufw deny out from any to 10.0.0.0/8 && \
ufw deny out from any to 172.16.0.0/12 && \
ufw deny out from any to 192.168.0.0/16 && \
ufw deny out from any to 100.64.0.0/10 && \
ufw deny out from any to 198.18.0.0/15 && \
ufw deny out from any to 169.254.0.0/16 && \
ufw deny out from any to 100.79.0.0/16 && \
ufw deny out from any to 100.113.0.0/16 && \
ufw deny out from any to 172.0.0.0/8 && \
ufw status

min_am=600
max_am=43200

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

cd $HOME && \
ver="1.22.0" && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile && \
source ~/.bash_profile && \
go version
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"

git clone -b v1.0.0 https://github.com/0glabs/0g-storage-node.git

cd $HOME/0g-storage-node
git stash
git fetch --all --tags
git checkout v1.0.0
git submodule update –init

mkdir -p /root/0g-storage-node/target/release
wget http://195.201.198.8:12385/zgs_node
mv zgs_node /root/0g-storage-node/target/release/zgs_node && chmod +x /root/0g-storage-node/target/release/zgs_node
wget http://195.201.198.8:12385/config-testnet-turbo.toml
mv config-testnet-turbo.toml /root/0g-storage-node/run/config-testnet-turbo.toml

rm -rf $HOME/0g-storage-node/run/db/flow_db
mkdir -p $HOME/0g-storage-node/run/db/
wget http://138.201.134.76:12312/storage_snap.tar.gz && tar -xzvf $HOME/storage_snap.tar.gz -C $HOME/0g-storage-node/run/db/

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

sed -i "s|^network_enr_address = \".*\"|network_enr_address = \"$(curl -s 2ip.ru)\"|" /root/0g-storage-node/run/config-testnet-turbo.toml
sed -i "s|^blockchain_rpc_endpoint = \".*\"| blockchain_rpc_endpoint = \"${RPC}\"|" /root/0g-storage-node/run/config-testnet-turbo.toml
sed -i "s|^miner_key = \".*\"|miner_key = \"${PRIVATE_KEY}\"|" /root/0g-storage-node/run/config-testnet-turbo.toml

systemctl daemon-reload && systemctl enable zgstorage && systemctl start zgstorage
