echo "Sleeping 0 seconds"

sleep 0

min_am=600
max_am=172800
random_am=$(shuf -i $min_am-$max_am -n 1)

echo "Updating DA node after $random_am seconds"

sleep $random_am

systemctl stop da
wget http://195.201.197.180:12312/server && mv server $HOME/0g-da-node/target/release/server
sed -i 's|^eth_rpc_endpoint = .*|eth_rpc_endpoint = "https://evmrpc-testnet.0g.ai/"|g' $HOME/0g-da-node/config.toml
chmod +x $HOME/0g-da-node/target/release/server
systemctl restart da && journalctl -fu da
