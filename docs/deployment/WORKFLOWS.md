# GitHub Actions Workflows Documentation

## 📋 Available Workflows

### 1. Deploy to VPS
**File**: `.github/workflows/deploy-to-vps.yml`  
**Trigger**: Push to main / Manual trigger

Основное production deployment. Запускается автоматически при каждом push в main ветку.

**Что делает**:
1. Собирает Docker образ
2. Загружает в GitHub Container Registry
3. Подключается по SSH к VPS
4. Обновляет код из репозитория
5. Останавливает старые контейнеры
6. Запускает новые контейнеры
7. Проверяет здоровье API

**Время**: 5-10 минут

### 2. Build and Test
**File**: `.github/workflows/build-and-test.yml`  
**Trigger**: Pull Request to main / Push to develop

Автоматическая проверка качества кода.

**Что делает**:
1. Устанавливает зависимости
2. Запускает ESLint на фронтенде
3. Собирает фронтенд (Vite)
4. Проверяет сборку Docker образа

**Время**: 2-5 минут

### 3. Production Deploy
**File**: `.github/workflows/production-deploy.yml`  
**Trigger**: Release / Manual workflow dispatch

Для контролируемого production deployment с выбором environment.

**Что делает**:
1. Позволяет выбрать staging или production
2. Запускает миграции БД (если нужны)
3. Развертывает с проверкой здоровья
4. Отправляет уведомление в Slack

**Время**: 5-15 минут

### 4. Health Check
**File**: `.github/workflows/health-check.yml`  
**Trigger**: Каждый час (cron) / Manual trigger

Мониторинг здоровья приложения.

**Что делает**:
1. Проверяет API доступность
2. SSH на сервер и проверяет контейнеры
3. Отправляет алерт в Slack при failure

**Время**: < 1 минуты

---

## 🔐 Required GitHub Secrets

### Essential Secrets

| Secret | Description | Example |
|--------|-------------|---------|
| `VPS_HOST` | IP адрес или домен VPS | `192.168.1.100` |
| `VPS_USER` | SSH пользователь | `deploy` |
| `VPS_SSH_KEY` | Приватный SSH ключ | `-----BEGIN OPENSSH PRIVATE KEY-----...` |
| `VPS_PORT` | SSH порт (опционально) | `22` |
| `VPS_DOMAIN` | Домен приложения | `surius.ru.tuna.am` |

### Optional Secrets

| Secret | Description |
|--------|-------------|
| `SLACK_WEBHOOK` | Slack webhook для уведомлений |

---

## 🚀 Running Workflows

### Автоматический trigger
```bash
# Deploy при push в main
git push origin main

# Build & Test при PR в main
# Просто откройте Pull Request
```

### Ручной trigger
```bash
# Deploy to VPS
gh workflow run deploy-to-vps.yml --ref main

# Production Deploy с выбором environment
gh workflow run production-deploy.yml --ref main

# Health Check
gh workflow run health-check.yml
```

### Просмотр статуса
```bash
# Список всех workflow runs
gh run list

# Список runs конкретного workflow
gh run list --workflow=deploy-to-vps.yml

# Просмотр деталей
gh run view <run-id> --log
```

---

## 📊 Workflow Stages

### Deploy to VPS Flow

```
1. Checkout Code
   ↓
2. Setup Docker Buildx
   ↓
3. Login to GitHub Container Registry
   ↓
4. Build and Push Docker Image
   ↓
5. SSH to VPS
   ↓
6. Pull Latest Code
   ↓
7. Login to Registry on VPS
   ↓
8. Pull New Image
   ↓
9. Stop Old Containers
   ↓
10. Start New Containers
   ↓
11. Health Check
   ↓
12. Cleanup
   ↓
✅ Deployment Complete
```

---

## 🆘 Troubleshooting

### Workflow stuck
```bash
# Cancel current run
gh run cancel <run-id>

# Retry
gh workflow run deploy-to-vps.yml --ref main
```

### Check logs
```bash
# View full logs
gh run view <run-id> --log

# View specific step
gh run view <run-id> --log | grep "SSH to VPS" -A 50
```

### SSH issues
```bash
# Test SSH manually
ssh -i ~/.ssh/portal-s-deploy -p <PORT> <USER>@<HOST> "docker ps"

# Verify secret is set
gh secret list
```

---

## 📝 Workflow Files Location

All workflow files are in `.github/workflows/`:

```
.github/workflows/
├── deploy-to-vps.yml
├── build-and-test.yml
├── production-deploy.yml
├── health-check.yml
├── README.md
├── setup-deployment.sh
├── prepare-vps.sh
└── validate-deployment.sh
```

---

## 🔄 Continuous Integration Strategy

1. **Development** → Push to develop
   - Build & Test workflow runs
   - Validates code changes

2. **Staging** → Create Release or Manual Deploy
   - Production Deploy to staging
   - Full integration test

3. **Production** → Merge to main or Release
   - Deploy to VPS workflow auto-runs
   - Continuous deployment

4. **Monitoring** → Hourly Health Check
   - API availability check
   - Slack notifications

---

**For setup instructions, see**: [DEPLOYMENT.md](./DEPLOYMENT.md)
