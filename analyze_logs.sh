#!/usr/bin/env bash
# Генерирует тестовый access.log и анализирует его (grep, awk, sort, uniq).

LOG="access.log"
LINES=400

# 1. Генерация лога
ips=(192.168.1.10 192.168.1.10 192.168.1.10 192.168.1.10
     10.0.0.5 10.0.0.5 10.0.0.5
     172.16.0.7 172.16.0.7
     192.168.1.20 10.0.0.9)
paths=(/api/users /api/login /api/orders /api/products /health)
methods=(GET GET GET POST PUT DELETE)
codes=(200 200 200 200 201 301 400 401 403 404 404 500 502 503)

: > "$LOG"
for ((i = 0; i < LINES; i++)); do
  ip=${ips[RANDOM % ${#ips[@]}]}
  path=${paths[RANDOM % ${#paths[@]}]}
  method=${methods[RANDOM % ${#methods[@]}]}
  code=${codes[RANDOM % ${#codes[@]}]}
  printf '%s - - [15/Aug/2026:10:%02d:%02d] "%s %s HTTP/1.1" %s\n' \
    "$ip" $((RANDOM % 60)) $((RANDOM % 60)) "$method" "$path" "$code" >> "$LOG"
done
echo "Сгенерирован файл $LOG: $(wc -l < "$LOG") строк"
echo

# 2. Общее количество запросов
total=$(wc -l < "$LOG")
echo "Общее количество запросов: $total"
echo

# 3. Топ-3 IP
echo "Топ-3 IP-адреса по числу запросов:"
grep -oE '^([0-9]{1,3}\.){3}[0-9]{1,3}' "$LOG" \
  | sort \
  | uniq -c \
  | sort -rn \
  | head -3 \
  | awk '{printf "  %s - %s запросов\n", $2, $1}'
echo

# 4. Ошибки 4xx и 5xx
awk '$NF ~ /^4[0-9][0-9]$/ {c4++}
     $NF ~ /^5[0-9][0-9]$/ {c5++}
     END {printf "Запросов с кодами 4xx: %d\nЗапросов с кодами 5xx: %d\n", c4, c5}' "$LOG"