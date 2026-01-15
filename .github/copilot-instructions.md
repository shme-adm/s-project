# Portal S - Инструкции для AI Агентов

**Проект**: Демо-портал интеграции ELMA365 для организации  
**Стек**: React 18 + Node.js + Express + MongoDB  
**Язык кода**: JavaScript/JSX

## 🏗️ Архитектура

Portal S - это монолитное приложение с разделением клиента и сервера:

- **Фронтенд** (`/client`): React 18 + Vite + MUI (Material-UI), Drag-and-drop с `@dnd-kit`
- **Бэкенд** (`/server`): Express + Mongoose, падение на mock-данные при недоступности MongoDB
- **Интеграция**: REST API ELMA365 (токен в `.env`)
- **Доставка**: Docker + Nginx, публичный доступ через Tuna туннели

### Главные компоненты

| Путь | Назначение |
|------|-----------|
| `/client/src/pages` | 5 основных страниц: Dashboard, Profile, Services, KnowledgeBase, OrgStructure |
| `/client/src/components` | Переиспользуемые компоненты (карточки, поиск, фильтры) |
| `/client/src/hooks` | Кастомные хуки для управления состоянием каждой страницы |
| `/client/src/store` | Global Context для sidebar/navigation |
| `/server/src/routes` | API эндпоинты: `/api/users`, `/api/requests`, `/api/elma` |
| `/server/src/models` | Mongoose схемы: User, SupportRequest |

## 🎯 Ключевые паттерны

### 1. **Управление состоянием: Кастомные хуки + localStorage**

Каждая страница использует свой хук (например, `useDashboardState`):

```javascript
// Хук сохраняет состояние в localStorage и восстанавливает при загрузке
const [widgets, setWidgets] = useState(defaultWidgets)
const [isEditMode, setIsEditMode] = useState(false)

useEffect(() => {
  const saved = localStorage.getItem(STORAGE_KEY)
  if (saved) setWidgets(JSON.parse(saved))
}, [])

useEffect(() => {
  if (!isLoading) localStorage.setItem(STORAGE_KEY, JSON.stringify(widgets))
}, [widgets, isLoading])
```

**Применение**: Используйте этот паттерн при добавлении новых страниц с состоянием, которое должно сохраняться.

### 2. **Fallback на mock-данные**

Backend имеет встроенный fallback при недоступности MongoDB:

```javascript
// /server/src/routes/users.js
router.get('/', async (req, res) => {
  try {
    const users = await User.find()
    res.json({ success: true, data: users, source: 'MongoDB' })
  } catch (error) {
    res.json({ success: true, data: mockUsers, source: 'Mock' }) // Fallback
  }
})
```

**Применение**: Добавляя новые API эндпоинты, всегда включайте mock-данные для разработки.

### 3. **API слой с axios**

Frontend использует axios для запросов. Mock API интегрирован в компоненты:

```javascript
// /client/src/api/KnowledgeApi.js - простая имитация
export const fetchKnowledgeData = async () => {
  return new Promise((resolve) => {
    setTimeout(() => resolve(administrativedata), 500)
  })
}
```

**Применение**: Сначала используйте mock, затем замените на реальный API вызов с axios.

### 4. **Drag-and-Drop на Dashboard**

Dashboard использует `@dnd-kit` для перемещения виджетов:

```javascript
// Виджеты имеют order и width поля для позиционирования
const defaultWidgets = [
  { id: 'news', title: 'Новости', order: 0, width: 1 },
  { id: 'events', title: 'Афиша', order: 1, width: 1 }
]
```

**Применение**: Новые виджеты добавляются в `defaultWidgets` с уникальным `id` и иконкой из `getIconComponent()`.

### 5. **MUI Темизация и стили**

Проект использует MUI v5 с inline `sx` props (no CSS files для компонентов):

```jsx
<Box sx={{ 
  display: 'flex', 
  flexDirection: 'column',
  gap: 2,
  '&:hover': { backgroundColor: 'primary.main' },
  transition: 'all 0.2s ease-in-out'
}}>
```

**Применение**: Используйте `sx` prop вместо CSS модулей. Цветовая палитра: primary (синий `#1e3a8a`), secondary (зеленый `#059669`).

### 6. **Mongoose Схемы с Pre-hooks**

User модель имеет pre-save hook для обновления `updatedAt`:

```javascript
userSchema.pre('save', function(next) {
  this.updatedAt = Date.now()
  next()
})
```

**Применение**: При создании новых моделей добавляйте аналогичные hooks для автоматического управления timestamps.

## 🚀 Команды и Workflows

### Разработка

```bash
npm run dev              # Запуск фронта + бэка параллельно
npm run dev:client      # Только Vite на порту 5173
npm run dev:server      # Nodemon сервер на порту 3000
npm run install:all     # Установка всех зависимостей
```

### Build и Production

```bash
npm run build           # Build клиента для production (Vite)
npm start              # Запуск production сервера
docker compose up -d   # Docker deployment
```

### Тестирование

```bash
npm run test:webhook   # node test-webhook.js - отправка тестовых данных
npm run tuna:status    # Проверка Tuna туннелей
```

**Важно**: При разработке новых API используйте `test-webhook.js` для отладки.

## 🔄 GitHub Actions Workflows

Автоматизированное развертывание на VPS через GitHub Actions (`.github/workflows/`):

| Workflow | Триггер | Назначение |
|----------|---------|-----------|
| `deploy-to-vps.yml` | Push в main | Автоматическое развертывание на VPS |
| `build-and-test.yml` | PR / Push в develop | Проверка сборки и lint |
| `production-deploy.yml` | Release / Manual | Production deployment с выбором environment |
| `health-check.yml` | Cron (каждый час) | Мониторинг здоровья API |

### Скрипты подготовки

```bash
# 1. Валидация конфигурации
bash .github/workflows/validate-deployment.sh

# 2. Подготовка VPS сервера
bash .github/workflows/prepare-vps.sh deploy@your-vps-ip

# 3. Настройка GitHub Secrets
bash .github/workflows/setup-deployment.sh
```

### Развертывание

```bash
# Автоматическое при push в main
git push origin main

# Ручное через GitHub CLI
gh workflow run deploy-to-vps.yml --ref main

# Просмотр статуса
gh run list --workflow=deploy-to-vps.yml --limit 5
```

### Makefile команды

```bash
make validate           # Валидация deployment конфигурации
make prepare-vps VPS_ADDR=user@host   # Подготовка VPS
make setup-gh           # Настройка GitHub Secrets
make deploy             # Ручное развертывание
```

Подробнее: [DEPLOYMENT.md](../../DEPLOYMENT.md) и [.github/workflows/README.md](README.md)

## 📁 Структурные соглашения

1. **Компоненты**: Один компонент = один файл, наименование PascalCase (`UserCard.jsx`)
2. **Хуки**: Наименование `use*` (`useDashboardState.jsx`)
3. **API**: Mock данные в `/mock` JSON файлах, реальные запросы через axios
4. **Маршруты**: Определены в `/server/src/routes/`, экспортированы в `index.js`
5. **Модели**: Mongoose схемы в `/server/src/models/`, pre/post hooks для logic

## 🔌 Интеграция ELMA365

- **URL**: `process.env.ELMA_API_URL`
- **Токен**: `process.env.ELMA_TOKEN`
- **Секретный ключ**: `process.env.ELMA_SECRET_KEY`

**Статус**: Интеграция не реализована. См. TODO в `/client/src/api/KnowledgeApi.js`.

## 🌐 Развертывание

### Локально
1. `npm run install:all`
2. Установить MongoDB локально или использовать mock
3. `npm run dev` - запуск на http://localhost:5173

### С Tuna туннелями
```bash
npm run tuna:domain  # Требует TUNA_TOKEN в .env
```

### Docker
```bash
docker compose up -d --build
# Frontend: http://localhost:5173
# API: http://localhost:3000
# MongoDB: localhost:27017
```

## ⚠️ Частые проблемы и решения

| Проблема | Решение |
|----------|---------|
| MongoDB не подключается | Используется mock-fallback. Проверьте `process.env.MONGODB_URI` |
| CORS ошибки при cross-domain запросах | Бэк имеет либеральную CORS политику (`origin: '*'`), проверьте OPTIONS запросы |
| localStorage данные не сохраняются | Убедитесь, что `isLoading === false` перед сохранением в хуках |
| Виджеты не драгаются на Dashboard | Проверьте, что компонент обернут в DndContext из `@dnd-kit` |
| Build не находит компоненты | Используйте относительные пути: `./components/Card.jsx` |

## 📝 Проверка перед коммитом

- [ ] Компоненты используют `sx` prop для стилей (MUI соглашение)
- [ ] Новые API имеют mock fallback
- [ ] Хуки с состоянием сохраняют данные в localStorage если требуется
- [ ] Mongoose модели имеют appropriate pre-hooks
- [ ] Маршруты обработают ошибки и возвращают структурированный JSON
- [ ] Нет жестко закодированных URL/токенов (используйте `.env`)

---

**Дата обновления**: 15 января 2026  
**Версия**: 1.0
