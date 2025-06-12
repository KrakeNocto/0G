#!/bin/bash

min_am=600
max_am=43200

random_am=$(shuf -i $min_am-$max_am -n 1)
total_sleep=$((random_am))

echo "Updating after after $total_sleep seconds"

sleep $total_sleep

systemctl stop 0gchaind 0ggeth

wget https://github.com/0glabs/0gchain-NG/releases/download/v1.2.0/galileo-v1.2.0.tar.gz
tar -xzf galileo-v1.2.0.tar.gz && mv /root/galileo-v1.2.0/bin/0gchaind /root/go/bin/ && mv /root/galileo-v1.2.0/bin/geth /root/go/bin/ && chmod +x /root/go/bin/0gchaind /root/go/bin/geth
rm -rf /root/galileo-v1.2.0/ && rm /root/galileo-v1.2.0.tar.gz

sudo sed -i -E 's/(--)(chain-spec|kzg\.trusted-setup-path|kzg\.implementation|engine\.jwt-secret-path|implementation=|block-store-service\.enabled|node-api\.enabled|node-api\.logging|node-api\.address)/\1chaincfg.\2/g' /etc/systemd/system/0gchaind.service
systemctl daemon-reload && systemctl restart 0gchaind 0ggeth && journalctl -fu 0gchaind
