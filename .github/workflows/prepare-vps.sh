#!/bin/bash

# Скрипт для подготовки VPS сервера к развертыванию
# Использование: bash prepare-vps.sh <user@host> [port]

if [ -z "$1" ]; then
    echo "❌ Использование: bash prepare-vps.sh <user@host> [port]"
    echo "Пример: bash prepare-vps.sh deploy@192.168.1.100 2222"
    exit 1
fi

VPS_ADDRESS="$1"
VPS_PORT="${2:-22}"
PROJECT_DIR="/opt/portal-s"

echo "🔧 Подготовка VPS сервера для Portal S"
echo "========================================"
echo "Адрес: $VPS_ADDRESS (порт $VPS_PORT)"
echo "Директория проекта: $PROJECT_DIR"
echo ""

# Скрипт для выполнения на сервере
read -r -d '' SETUP_SCRIPT << 'EOF' || true
#!/bin/bash
set -e

echo "📦 Обновление системы..."
sudo apt-get update
sudo apt-get upgrade -y

echo "📚 Установка Git..."
sudo apt-get install -y git

echo "🌐 Установка Curl..."
sudo apt-get install -y curl

echo "🐳 Установка Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    echo "✅ Docker установлен"
else
    echo "✅ Docker уже установлен"
fi

echo "🐳 Установка Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose установлен"
else
    echo "✅ Docker Compose уже установлен"
fi

echo "👤 Создание пользователя deploy..."
if ! id -u deploy > /dev/null 2>&1; then
    sudo useradd -m -s /bin/bash deploy
    sudo usermod -aG docker deploy
    echo "✅ Пользователь deploy создан"
else
    echo "✅ Пользователь deploy уже существует"
fi

echo "📁 Подготовка директории проекта..."
sudo mkdir -p /opt/portal-s
sudo chown deploy:deploy /opt/portal-s
sudo chmod 755 /opt/portal-s

echo "🔐 Установка прав доступа..."
sudo chown -R deploy:deploy /opt/portal-s

echo "✅ Сервер подготовлен и готов к развертыванию!"
EOF

# Копируем скрипт на сервер и выполняем
ssh -p "$VPS_PORT" "$VPS_ADDRESS" "$(echo "$SETUP_SCRIPT")"

echo ""
echo "🚀 Следующие шаги:"
echo ""
echo "1. Клонируйте репозиторий на сервер:"
echo "   ssh -p $VPS_PORT $VPS_ADDRESS"
echo "   cd /opt/portal-s"
echo "   git clone https://github.com/your-username/s-project.git ."
echo ""
echo "2. Создайте .env файл с переменными окружения:"
echo "   scp -P $VPS_PORT .env.example $VPS_ADDRESS:/opt/portal-s/.env"
echo "   ssh -p $VPS_PORT $VPS_ADDRESS nano /opt/portal-s/.env"
echo ""
echo "3. Запустите контейнеры:"
echo "   ssh -p $VPS_PORT $VPS_ADDRESS"
echo "   cd /opt/portal-s"
echo "   docker compose up -d"
echo ""
echo "✅ VPS сервер подготовлен!"
