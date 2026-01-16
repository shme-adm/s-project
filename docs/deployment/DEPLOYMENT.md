# 🚀 Portal S - Quick Deployment Guide

## ⚡ Первое развертывание (Новое)

**ВАЖНО:** При первом развертывании требуется только файл `.env`!

Все остальное будет создано и загружено автоматически:

```bash
# 1. Убедитесь, что .env готов локально
ls -la | grep .env

# 2. Подготовьте VPS (если еще не подготовлен)
bash .github/workflows/prepare-vps.sh deploy@your-vps-ip 22

# 3. Скопируйте .env на сервер
scp .env deploy@your-vps-ip:/opt/portal-s/.env

# 4. Запустите первый деплой
git push origin main
```

---

## 5-Минутный старт

### 1️⃣ Подготовка VPS сервера (5 минут)

```bash
# На вашей локальной машине:
bash .github/workflows/prepare-vps.sh deploy@your-vps-ip 22
```

Скрипт установит на сервер:
- Docker и Docker Compose
- Git
- Пользователя `deploy` с доступом к Docker

### 2️⃣ Настройка GitHub Secrets (2 минуты)

```bash
# Установите GitHub CLI если не установлен
# https://cli.github.com

# Запустите интерактивный скрипт настройки
bash .github/workflows/setup-deployment.sh
```

Скрипт попросит:
- IP VPS сервера
- Логин для SSH
- Порт SSH
- Домен приложения
- Путь к SSH ключу

### 3️⃣ Первое развертывание

**Вариант A: Автоматическое (при push в main)**
```bash
# Сначала скопируйте .env на сервер!
scp .env deploy@your-vps-ip:/opt/portal-s/.env
ssh -p 22 deploy@your-vps-ip "chmod 600 /opt/portal-s/.env"

# Затем push запустит workflow
git push origin main
```

**Вариант B: Ручной запуск**
```bash
# Сначала скопируйте .env на сервер!
scp .env deploy@your-vps-ip:/opt/portal-s/.env

# Через GitHub CLI
gh workflow run deploy-to-vps.yml --ref main

# Или через GitHub UI:
# 1. Перейти в Actions
# 2. Deploy to VPS
# 3. Run workflow
```

## 📋 Требования перед началом

- [ ] GitHub Actions включен в репозитории
- [ ] GitHub CLI установлен (`gh --version`)
- [ ] SSH ключ создан и скопирован на VPS
- [ ] VPS имеет открытые порты 80 и 443
- [ ] Минимум 2GB RAM на VPS

## 🔑 SSH ключ - Детально

### Если ключ еще не создан:

```bash
# Генерируем новый ED25519 ключ (рекомендуется)
ssh-keygen -t ed25519 -f ~/.ssh/portal-s-deploy -N ""

# Или RSA ключ (если не поддерживается ED25519)
ssh-keygen -t rsa -b 4096 -f ~/.ssh/portal-s-deploy -N ""
```

### Копируем публичный ключ на VPS:

```bash
# Способ 1: ssh-copy-id (самый легкий)
ssh-copy-id -i ~/.ssh/portal-s-deploy.pub -p 22 deploy@your-vps-ip

# Способ 2: Ручной копирование
cat ~/.ssh/portal-s-deploy.pub | ssh -p 22 deploy@your-vps-ip 'cat >> ~/.ssh/authorized_keys'

# Способ 3: Если ssh-copy-id не работает
scp -P 22 ~/.ssh/portal-s-deploy.pub deploy@your-vps-ip:~/
ssh -p 22 deploy@your-vps-ip 'mkdir -p ~/.ssh && cat ~/portal-s-deploy.pub >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys'
```

### Проверяем подключение:

```bash
# Должно подключиться без пароля
ssh -i ~/.ssh/portal-s-deploy -p 22 deploy@your-vps-ip "docker --version"
```

## 🔐 Защита .env файла на сервере

**ВАЖНО**: .env должен существовать на VPS и НЕ находиться в git

```bash
# На сервере через SSH:
ssh deploy@your-vps-ip

cd /opt/portal-s

# Копируем пример файла и редактируем
cp .env.example .env
nano .env  # или vi .env

# Устанавливаем права доступа
chmod 600 .env
```

Обязательные переменные:
```
MONGODB_URI=mongodb://admin:password@mongodb:27017/portal-s
MONGO_ROOT_USERNAME=admin
MONGO_ROOT_PASSWORD=your-secure-password
CLIENT_URL=https://your-domain.com
API_URL=https://api-your-domain.com
ELMA_TOKEN=your-token
```

## 📊 Мониторинг deployment

### Просмотр статуса workflow:

```bash
# GitHub CLI
gh run list --workflow=deploy-to-vps.yml --limit 5

# Просмотр деталей последнего run
gh run view <run-id> --log
```

### SSH на сервер и проверка:

```bash
ssh deploy@your-vps-ip

# Просмотр контейнеров
docker ps -a

# Логи backend сервера
docker compose logs -f backend

# Логи MongoDB
docker compose logs -f mongodb

# Проверка API
curl http://localhost:3000/api/health
```

## 🆘 Troubleshooting

### Deployment падает на "Stopping old containers"

**Проблема**: SSH подключение работает, но скрипт падает на `docker compose down`

**Решение**:
```bash
# На сервере проверьте, что docker-compose.yml существует
ssh deploy@your-vps-ip "ls -la /opt/portal-s/"

# Убедитесь, что были выполнены команды на VPS:
ssh deploy@your-vps-ip "cd /opt/portal-s && git status"
```

### "Permission denied (publickey)" при SSH

**Проблема**: GitHub Actions не может подключиться к VPS

**Решение**:
```bash
# Проверьте, что SSH ключ содержимое скопировано в .env
# Выведите приватный ключ еще раз и переустановите secret
cat ~/.ssh/portal-s-deploy

# Переустановите в GitHub:
gh secret set VPS_SSH_KEY --body "$(cat ~/.ssh/portal-s-deploy)"
```

### MongoDB connection error

**Проблема**: Backend контейнер не может подключиться к MongoDB

**Решение**:
```bash
# На сервере проверьте MongoDB
ssh deploy@your-vps-ip
docker compose logs mongodb

# Убедитесь, что переменные окружения правильные в .env
cat .env | grep MONGO

# Перезагрузите контейнеры
docker compose down
docker compose up -d
```

### API возвращает 502 Bad Gateway

**Проблема**: Nginx не может достичь backend контейнер

**Решение**:
```bash
# Проверьте, что backend запущен
docker ps | grep backend

# Проверьте логи backend
docker compose logs backend | tail -50

# Убедитесь, что nginx.conf содержит правильный upstream
docker compose exec nginx cat /etc/nginx/nginx.conf | grep upstream
```

## 📝 После успешного deployment

1. **Проверьте приложение**:
   - Откройте https://your-domain.com
   - Проверьте API: https://api-your-domain.com/api/health

2. **Настройте мониторинг**:
   - Добавьте uptime monitoring (UptimeRobot, Pingdom)

3. **Резервные копии**:
   - Настройте автоматический backup MongoDB
   - Проверьте, что логи сохраняются на диск

## 🔄 Обновления и Rollback

### Обновление (просто push в main):
```bash
git add .
git commit -m "Updated feature XYZ"
git push origin main
# GitHub Actions автоматически развернет обновление
```

### Откат на предыдущую версию:
```bash
# На сервере
ssh deploy@your-vps-ip
cd /opt/portal-s

# Просмотр истории
git log --oneline | head -10

# Откат на конкретный коммит
git reset --hard <commit-id>
docker compose down
docker compose up -d
```

## 🚨 Production Checklist

Перед первым production deployment:

- [ ] `.env` файл на сервере содержит все переменные
- [ ] MongoDB пароль изменен с default
- [ ] CORS настроен правильно (`CLIENT_URL` и `API_URL`)
- [ ] SSL сертификаты сгенерированы (Let's Encrypt через Nginx)
- [ ] Backup MongoDB настроен
- [ ] Логирование настроено
- [ ] Мониторинг настроен
- [ ] SSH ключи защищены (600 permissions)
- [ ] Docker images регулярно очищаются

## 📚 Дополнительные ресурсы

- `.github/workflows/README.md` - Подробная документация workflows
- `docs/DOCKER_README.md` - Docker конфигурация
- `nginx.conf` - Nginx конфигурация
- `docker-compose.yml` - Docker Compose конфигурация

---

**Нужна помощь?** Проверьте логи workflow на GitHub Actions и SSH логи на сервере.
