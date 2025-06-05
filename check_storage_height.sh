#!/bin/bash

IP_FILE="ips.txt"

if [[ ! -f "$IP_FILE" ]]; then
  echo "Файл $IP_FILE не найден."
  exit 1
fi

while IFS= read -r ip || [[ -n "$ip" ]]; do
  full_address="${ip}:5678"

  response=$(curl -s --max-time 5 -X POST "http://$full_address" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"zgs_getStatus","params":[],"id":1}')

  if [[ -z "$response" ]]; then
    echo "$full_address — нет ответа"
    continue
  fi

  height=$(echo "$response" | jq -r '.result.logSyncHeight // empty')

  if [[ -n "$height" ]]; then
    echo "$full_address — logSyncHeight: $height"
  else
    echo "$full_address — нет logSyncHeight в ответе"
  fi

done < "$IP_FILE"
