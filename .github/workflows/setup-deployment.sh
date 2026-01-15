#!/bin/bash

# Скрипт для настройки GitHub Actions Secrets для VPS развертывания
# Использование: bash ./setup-deployment.sh

set -e

echo "🔧 GitHub Actions VPS Deployment Setup"
echo "======================================="
echo ""

# Проверяем наличие GitHub CLI
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI не установлен"
    echo "Установите из: https://cli.github.com"
    exit 1
fi

# Проверяем, залогинены ли в GitHub
if ! gh auth status &> /dev/null; then
    echo "❌ Не залогинены в GitHub"
    echo "Запустите: gh auth login"
    exit 1
fi

echo "📋 Введите данные VPS сервера:"
echo ""

read -p "VPS Host (IP или домен): " VPS_HOST
read -p "VPS User (логин для SSH): " VPS_USER
read -p "VPS Port (или Enter для 22): " VPS_PORT
VPS_PORT=${VPS_PORT:-22}
read -p "VPS Domain (домен приложения): " VPS_DOMAIN

# Проверяем путь к SSH ключу
echo ""
read -p "Путь к приватному SSH ключу (Enter для ~/.ssh/id_rsa): " SSH_KEY_PATH
SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_rsa}

if [ ! -f "$SSH_KEY_PATH" ]; then
    echo "❌ SSH ключ не найден: $SSH_KEY_PATH"
    echo ""
    echo "Для генерации нового ключа выполните:"
    echo "  ssh-keygen -t ed25519 -f $SSH_KEY_PATH -N \"\""
    echo ""
    echo "Затем скопируйте публичный ключ на сервер:"
    echo "  ssh-copy-id -i ${SSH_KEY_PATH}.pub $VPS_USER@$VPS_HOST -p $VPS_PORT"
    exit 1
fi

# Читаем SSH ключ
SSH_KEY_CONTENT=$(cat "$SSH_KEY_PATH")

# Получаем текущий репозиторий
REPO=$(gh repo view --json nameWithOwner -q)

echo ""
echo "📝 Установка GitHub Secrets для репозитория: $REPO"
echo ""

# Устанавливаем секреты
echo "Setting VPS_HOST = $VPS_HOST"
gh secret set VPS_HOST --body "$VPS_HOST" --repo "$REPO"

echo "Setting VPS_USER = $VPS_USER"
gh secret set VPS_USER --body "$VPS_USER" --repo "$REPO"

echo "Setting VPS_PORT = $VPS_PORT"
gh secret set VPS_PORT --body "$VPS_PORT" --repo "$REPO"

echo "Setting VPS_DOMAIN = $VPS_DOMAIN"
gh secret set VPS_DOMAIN --body "$VPS_DOMAIN" --repo "$REPO"

echo "Setting VPS_SSH_KEY (приватный ключ)"
gh secret set VPS_SSH_KEY --body "$SSH_KEY_CONTENT" --repo "$REPO"

echo ""
echo "✅ Все секреты установлены успешно!"
echo ""
echo "📊 Проверка установленных секретов:"
gh secret list --repo "$REPO"

echo ""
echo "🚀 Готово! Теперь можно запустить deployment"
echo ""
echo "Варианты:"
echo "1. Git push в main ветку - workflow запустится автоматически"
echo "2. Через GitHub UI: Actions > Deploy to VPS > Run workflow"
