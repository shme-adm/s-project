#!/bin/bash

# Скрипт для проверки готовности deployment конфигурации
# Использование: bash validate-deployment.sh

set -e

echo "🔍 Portal S - Deployment Configuration Validator"
echo "================================================="
echo ""

ERRORS=0
WARNINGS=0

# Функции для вывода
error() {
    echo "❌ $1"
    ((ERRORS++))
}

warning() {
    echo "⚠️  $1"
    ((WARNINGS++))
}

success() {
    echo "✅ $1"
}

# Проверка 1: .env файл
if [ -f ".env" ]; then
    success ".env file exists"
    
    # Проверяем необходимые переменные
    required_vars=("MONGODB_URI" "MONGO_ROOT_USERNAME" "MONGO_ROOT_PASSWORD" "PORT")
    
    for var in "${required_vars[@]}"; do
        if grep -q "^$var=" .env; then
            success "  $var is set"
        else
            error "  $var is missing in .env"
        fi
    done
else
    warning ".env file not found (required on production server)"
fi

# Проверка 2: Docker файлы
if [ -f "Dockerfile" ]; then
    success "Dockerfile exists"
else
    error "Dockerfile not found"
fi

if [ -f "docker-compose.yml" ]; then
    success "docker-compose.yml exists"
else
    error "docker-compose.yml not found"
fi

# Проверка 3: Конфигурация nginx
if [ -f "nginx.conf" ]; then
    success "nginx.conf exists"
    
    # Проверяем базовую структуру
    if grep -q "upstream" nginx.conf; then
        success "  nginx upstream configured"
    else
        warning "  nginx upstream not found"
    fi
else
    warning "nginx.conf not found"
fi

# Проверка 4: GitHub workflows
echo ""
echo "🔄 Checking GitHub Actions workflows..."

workflow_files=(
    ".github/workflows/deploy-to-vps.yml"
    ".github/workflows/build-and-test.yml"
    ".github/workflows/production-deploy.yml"
)

for workflow in "${workflow_files[@]}"; do
    if [ -f "$workflow" ]; then
        success "  $(basename $workflow)"
    else
        error "  $(basename $workflow) not found"
    fi
done

# Проверка 5: Скрипты подготовки
echo ""
echo "📝 Checking setup scripts..."

scripts=(
    ".github/workflows/setup-deployment.sh"
    ".github/workflows/prepare-vps.sh"
    ".github/workflows/validate-deployment.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            success "  $(basename $script) (executable)"
        else
            warning "  $(basename $script) (not executable, run: chmod +x $script)"
        fi
    else
        error "  $(basename $script) not found"
    fi
done

# Проверка 6: Документация
echo ""
echo "📚 Checking documentation..."

docs=(
    "docs/deployment/DEPLOYMENT.md"
    ".github/workflows/README.md"
    "example.env"
)

for doc in "${docs[@]}"; do
    if [ -f "$doc" ]; then
        success "  $doc"
    else
        warning "  $doc not found"
    fi
done

# Проверка 7: GitHub CLI
echo ""
echo "🔧 Checking tools..."

if command -v gh &> /dev/null; then
    success "GitHub CLI installed ($(gh --version))"
    
    # Проверяем, залогинены ли
    if gh auth status &> /dev/null; then
        success "  GitHub CLI authenticated"
    else
        warning "  GitHub CLI not authenticated (run: gh auth login)"
    fi
else
    warning "GitHub CLI not installed (install from https://cli.github.com)"
fi

if command -v docker &> /dev/null; then
    success "Docker installed ($(docker --version))"
else
    warning "Docker not installed locally (required for local testing)"
fi

if command -v ssh &> /dev/null; then
    success "SSH client installed"
else
    error "SSH client not installed"
fi

# Проверка 8: Git конфигурация
echo ""
echo "📦 Checking Git configuration..."

if [ -d ".git" ]; then
    success "Git repository exists"
    
    REMOTE=$(git remote get-url origin 2>/dev/null || echo "")
    if [ -n "$REMOTE" ]; then
        success "  Remote origin: $REMOTE"
    else
        warning "  No remote origin configured"
    fi
    
    BRANCH=$(git rev-parse --abbrev-ref HEAD)
    success "  Current branch: $BRANCH"
else
    error "Not a git repository"
fi

# Проверка 9: SSH ключ
echo ""
echo "🔐 Checking SSH configuration..."

if [ -n "$SSH_KEY_PATH" ]; then
    if [ -f "$SSH_KEY_PATH" ]; then
        success "SSH key exists: $SSH_KEY_PATH"
    else
        warning "SSH key not found at: $SSH_KEY_PATH"
    fi
elif [ -f "$HOME/.ssh/id_rsa" ]; then
    success "Default SSH key found: $HOME/.ssh/id_rsa"
elif [ -f "$HOME/.ssh/id_ed25519" ]; then
    success "ED25519 SSH key found: $HOME/.ssh/id_ed25519"
else
    warning "No SSH keys found in ~/.ssh/"
fi

# Итоговый отчет
echo ""
echo "================================================="
echo "📊 Validation Report"
echo "================================================="

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo "✅ All checks passed! Ready for deployment."
    echo ""
    echo "Next steps:"
    echo "1. bash .github/workflows/prepare-vps.sh <user@host>"
    echo "2. bash .github/workflows/setup-deployment.sh"
    echo "3. git push origin main"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo "⚠️  $WARNINGS warnings (non-critical)"
    echo "✅ Configuration is valid, but check warnings"
    exit 0
else
    echo "❌ $ERRORS errors found"
    if [ $WARNINGS -gt 0 ]; then
        echo "⚠️  $WARNINGS warnings"
    fi
    echo ""
    echo "Fix errors before proceeding with deployment"
    exit 1
fi
