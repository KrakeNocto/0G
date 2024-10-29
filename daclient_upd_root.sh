systemctl stop daclient

wget http://116.202.52.168:12312/batcher http://116.202.52.168:12312/combined http://116.202.52.168:12312/server

mv batcher $HOME/0g-da-client/disperser/bin/ && mv combined $HOME/0g-da-client/disperser/bin/ && mv server $HOME/0g-da-client/disperser/bin/
chmod +x $HOME/0g-da-client/disperser/bin/batcher && chmod +x $HOME/0g-da-client/disperser/bin/combined && chmod +x $HOME/0g-da-client/disperser/bin/server

sed -ie "s|http://[^ ]*|https://evm-rpc.0g.testnet.node75.org/|" /etc/systemd/system/daclient.service
sed -ie 's|indexer = "kv"|indexer = "null"|'  /root/.0gchain/config/config.toml
systemctl restart ogd

rm -rf /root/.0gchain/data/tx_index.db

rm daclient_upd.sh

systemctl daemon-reload && systemctl restart daclient && journalctl -fu daclient
