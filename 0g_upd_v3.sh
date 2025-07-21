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

echo "Uodating Storage after $total_sleep seconds"

sleep $total_sleep

systemctl stop --now zgstorage || systemctl stop --now zgs

wget http://195.201.198.8:12385/zgs_node
mv zgs_node /root/0g-storage-node/target/release/zgs_node && chmod +x /root/0g-storage-node/target/release/zgs_node

systemctl daemon-reload && systemctl start --now zgstorage || systemctl start --now zgs

sleep 15

tail -f /root/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)
