#!/usr/bin/env bash
# Проверка доступности API
# Использование: ./check_api.sh <URL>
# Код возврата: 0 - API доступен (HTTP 200), 1 - ошибка

if [ $# -ne 1 ]; then
  echo "Использование: $0 <URL>"
  exit 1
fi

url="$1"

code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url")

if [ "$code" -eq 200 ]; then
  echo "API доступен"
  exit 0
else
  echo "API недоступен, код ответа: $code"
  exit 1
fi