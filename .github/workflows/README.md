# GitHub Actions для Portal S

## Workflows

### 1. `deploy-to-vps.yml` - Основное развертывание
- **Триггер**: Push в `main` ветку или ручной запуск
- **Что делает**:
  - Собирает Docker образ и загружает в GitHub Container Registry
  - Подключается к VPS через SSH
  - Обновляет код из репозитория
  - Останавливает старые контейнеры
  - Запускает новые контейнеры
  - Проверяет здоровье API

### 2. `build-and-test.yml` - Проверка сборки
- **Триггер**: Pull Request в `main` или Push в `develop`
- **Что делает**:
  - Устанавливает зависимости
  - Проверяет lint клиента
  - Собирает клиент (Vite)
  - Проверяет сборку Docker образа

### 3. `production-deploy.yml` - Production развертывание
- **Триггер**: Publication релиза или ручной запуск с выбором environment
- **Что делает**:
  - Определяет, в какой environment развертывать
  - Запускает миграции БД (если нужны)
  - Развертывает с проверкой здоровья
  - Отправляет уведомление в Slack

## Секреты GitHub (Settings > Secrets and variables > Actions)

Требуемые секреты для развертывания:

| Секрет | Описание | Пример |
|--------|---------|--------|
| `VPS_HOST` | IP адрес VPS сервера | `192.168.1.100` |
| `VPS_USER` | Пользователь для SSH подключения | `deploy` |
| `VPS_SSH_KEY` | Приватный SSH ключ (содержимое файла) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VPS_PORT` | Порт SSH (опционально, по умолчанию 22) | `2222` |
| `VPS_DOMAIN` | Домен приложения (для уведомлений) | `surius.ru.tuna.am` |
| `SLACK_WEBHOOK` | Webhook для Slack уведомлений (опционально) | `https://hooks.slack.com/...` |

## Как установить SSH ключ

### На локальной машине:
```bash
# Генерируем SSH ключ (если не существует)
ssh-keygen -t ed25519 -f ~/.ssh/portal-s-deploy -N ""

# Копируем публичный ключ на VPS
ssh-copy-id -i ~/.ssh/portal-s-deploy.pub user@vps_ip

# Выводим приватный ключ
cat ~/.ssh/portal-s-deploy
```

### В GitHub:
1. Перейти в Settings > Secrets and variables > Actions
2. Нажать "New repository secret"
3. Имя: `VPS_SSH_KEY`
4. Значение: Вставить содержимое приватного ключа

## Подготовка VPS сервера

```bash
# 1. Установить Docker и Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 2. Установить Git
sudo apt-get update
sudo apt-get install -y git

# 3. Создать пользователя для deployment (опционально)
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy

# 4. Клонировать проект
sudo mkdir -p /opt/portal-s
sudo chown deploy:deploy /opt/portal-s
cd /opt/portal-s
git clone https://github.com/your-username/s-project.git .

# 5. Создать .env файл с нужными переменными
# ВАЖНО: .env должен находиться на сервере
cat > .env << EOF
PORT=3000
NODE_ENV=production
MONGODB_URI=mongodb://admin:password123@mongodb:27017/portal-s?authSource=admin
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=password123
CLIENT_URL=https://your-domain.com
API_URL=https://api-your-domain.com
ELMA_API_URL=https://your-elma-instance.elma365.ru/
ELMA_TOKEN=your-token
ELMA_SECRET_KEY=your-secret
TUNA_TOKEN=your-tuna-token
EOF

# 6. Разрешить чтение .env
chmod 600 .env
```

## Запуск deployment вручную

### Через GitHub UI:
1. Перейти в Actions > Deploy to VPS
2. Нажать "Run workflow"
3. Выбрать ветку `main`
4. Нажать "Run workflow"

### Через GitHub CLI:
```bash
# Просмотр workflows
gh workflow list

# Запуск workflow
gh workflow run deploy-to-vps.yml --ref main

# Просмотр последних runs
gh run list
```

## Логирование и отладка

### Просмотр логов workflow:
1. Перейти в Actions > Deploy to VPS
2. Выбрать последний run
3. Развернуть секции для деталей

### SSH на сервер и проверка контейнеров:
```bash
ssh deploy@your-vps-ip

# Просмотр контейнеров
docker ps -a

# Просмотр логов
docker compose logs -f backend
docker compose logs -f mongodb

# Перезагрузить контейнеры
docker compose down
docker compose up -d

# Проверить здоровье API
curl http://localhost:3000/api/health
```

## Часто используемые команды

```bash
# Остановить все контейнеры
docker compose down

# Перезагрузить с пересборкой
docker compose up -d --build

# Просмотр занимаемого пространства
docker system df

# Очистка неиспользуемых ресурсов
docker system prune -a --volumes

# Просмотр переменных контейнера
docker compose config
```

## Troubleshooting

### Deployment зависает
- Проверьте доступность VPS: `ping <VPS_IP>`
- Проверьте SSH доступ: `ssh -i key.pem user@<VPS_IP>`
- Проверьте размер Docker образа: `docker images`

### Контейнер падает после развертывания
- Проверьте логи: `docker compose logs backend`
- Убедитесь, что все переменные в .env установлены
- Проверьте доступность MongoDB

### CORS ошибки после развертывания
- Убедитесь, что `CLIENT_URL` и `API_URL` установлены правильно
- Проверьте, что Nginx корректно проксирует запросы
- Проверьте конфиг Nginx: `/etc/nginx/nginx.conf`

---

**Для вопросов и обновлений**: Смотрите `.github/workflows/` в репозитории
