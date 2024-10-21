systemctl stop daclient

wget http://116.202.52.168:12312/batcher http://116.202.52.168:12312/combined http://116.202.52.168:12312/server

mv batcher /root/0g-da-client/disperser/bin/ && mv combined /root/0g-da-client/disperser/bin/ && mv server /root/0g-da-client/disperser/bin/
chmod +x /root/0g-da-client/disperser/bin/batcher && chmod +x /root/0g-da-client/disperser/bin/combined && chmod +x /root/0g-da-client/disperser/bin/server

sed -ie "s|http://[^ ]*|https://evm-rpc.0g.testnet.node75.org/|" /etc/systemd/system/daclient.service

rm daclient_upd.sh

systemctl daemon-reload && systemctl restart daclient && journalctl -fu daclient
