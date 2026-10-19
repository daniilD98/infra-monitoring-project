# infra-monitoring-project

Система мониторинга доступности API: Bash-скрипты для проверки и анализа логов, контейнеризированный стенд (Docker Compose) и CI/CD на GitHub Actions.

## Структура проекта

| Файл | Назначение |
|------|-----------|
| `check_api.sh` | Проверка доступности API по HTTP-коду |
| `analyze_logs.sh` | Генерация и анализ `access.log` |
| `docker-compose.yml` | Стенд: `api` (http-echo) и `proxy` (nginx) |
| `nginx.conf` | Конфигурация прокси nginx |
| `.github/workflows/ci.yml` | CI-пайплайн GitHub Actions |
| `docs/` | Дамп трафика Wireshark и скриншоты |

## Быстрый старт

```bash
git clone https://github.com/daniilD98/infra-monitoring-project.git
cd infra-monitoring-project
chmod +x check_api.sh analyze_logs.sh
```

Требуются Bash, curl и Docker (с Docker Compose).

## Скрипты

### check_api.sh

Принимает URL, возвращает код `0`, если API ответил `200`, иначе `1`.

```bash
./check_api.sh https://httpbin.org/status/200   # API доступен, код возврата 0
./check_api.sh https://httpbin.org/status/500   # API недоступен, код возврата 1
./check_api.sh                                  # подсказка по использованию, код 1
echo $?                                         # проверка кода возврата
```

### analyze_logs.sh

Генерирует `access.log` (400 строк) и выводит: общее число запросов, топ-3 IP-адреса, количество ответов 4xx и 5xx.

```bash
./analyze_logs.sh
```

## Docker Compose

```bash
docker-compose up -d        # запуск стенда
docker-compose ps           # статус контейнеров
curl http://localhost:80    # ответ: Monitoring Service Active
docker-compose down         # остановка
```

Сервис `api` (`hashicorp/http-echo`) слушает порт 8080 только во внутренней сети `monitoring-net`. Сервис `proxy` (`nginx:alpine`) принимает запросы на порту 80 и проксирует их на `api:8080`.

## CI/CD

При создании Pull Request в `main` GitHub Actions проверяет синтаксис скриптов (`bash -n`) и запускает `check_api.sh https://httpbin.org/status/200`.

## Деплой на удалённый сервер (SSH/SCP)

В примерах используются условные значения: пользователь `deploy`, сервер `203.0.113.10`. Подставьте свои.

### 1. Генерация SSH-ключей

```bash
ssh-keygen -t ed25519 -C "deploy-key"
```

Ключи сохраняются в `~/.ssh/`: приватный `id_ed25519` (никому не передавать) и публичный `id_ed25519.pub`. Для защиты ключа рекомендуется задать passphrase.

### 2. Копирование публичного ключа на сервер

```bash
ssh-copy-id deploy@203.0.113.10
```

После этого вход выполняется по ключу, без пароля. В Windows PowerShell, где `ssh-copy-id` может отсутствовать:

```powershell
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh deploy@203.0.113.10 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

Проверка подключения:

```bash
ssh deploy@203.0.113.10
```

### 3. Передача проекта на сервер

Вариант А: архив и scp.

```bash
tar -czf project.tar.gz check_api.sh analyze_logs.sh docker-compose.yml nginx.conf
scp project.tar.gz deploy@203.0.113.10:/home/deploy/
ssh deploy@203.0.113.10 "mkdir -p infra-monitoring && tar -xzf project.tar.gz -C infra-monitoring"
```

Вариант Б: tar через конвейер ssh, без промежуточного файла.

```bash
tar -czf - check_api.sh analyze_logs.sh docker-compose.yml nginx.conf \
  | ssh deploy@203.0.113.10 "mkdir -p infra-monitoring && tar -xzf - -C infra-monitoring"
```

Одиночный файл можно отправить напрямую:

```bash
scp docker-compose.yml deploy@203.0.113.10:/home/deploy/infra-monitoring/
```

### 4. Запуск на сервере

```bash
ssh deploy@203.0.113.10 "cd infra-monitoring && docker-compose up -d && docker-compose ps"
ssh deploy@203.0.113.10 "cd infra-monitoring && ./check_api.sh http://localhost:80"
```

### Рекомендации по безопасности

- Не передавать и не коммитить приватный ключ.
- После настройки ключей отключить вход по паролю (`PasswordAuthentication no` в `/etc/ssh/sshd_config`).
- Использовать отдельного пользователя без root-прав для деплоя.