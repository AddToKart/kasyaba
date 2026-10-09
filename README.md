# KASYABA

Personal financial tracker for Android with income and expense tracking, savings goals, bill reminders, explainable financial forecasting, predictive alerts, and a financial health score.

## Tech Stack

- **Mobile**: Flutter (Android)
- **API**: Express.js with TypeScript
- **Database**: PostgreSQL (via Supabase)
- **ORM**: Prisma
- **Auth**: JWT + refresh tokens, Google Sign-In

## Getting Started

### Prerequisites

- Flutter SDK 3.44.x (Dart SDK 3.12.x)
- Node.js LTS
- Docker & Docker Compose (for local PostgreSQL)

### Backend Setup

```bash
cd kasyaba-backend

# Copy environment variables
cp .env.example .env
# Edit .env with your values

# Install dependencies
npm install

# Generate Prisma client
npx prisma generate

# Run database migrations
npx prisma migrate dev

# Seed default categories
npx tsx prisma/seed.ts

# Start development server
npm run dev
```

### Flutter Setup

```bash
cd kasyaba-app

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Android Release Build

Release builds must point at the production API over HTTPS:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://<your-api-domain> \
  --obfuscate --split-debug-info=build/symbols
```

Debug builds default to `http://10.0.2.2:3000`, and cleartext HTTP is allowed in
debug builds only (`android/app/src/debug/res/xml/network_security_config.xml`).
A release build compiled without `API_BASE_URL` shows a configuration error
instead of silently targeting localhost.

### Docker Development

```bash
# Start PostgreSQL, API, and Worker in development mode
# The automatically loaded docker-compose.override.yml mounts the backend source.
docker compose up --build

# After the first build, source changes hot-reload without rebuilding.
docker compose up

# Follow backend logs
docker compose logs -f api worker

# Apply a migration added while the containers are already running
docker compose exec api npx prisma migrate deploy

# Regenerate Prisma Client after changing prisma/schema.prisma
docker compose exec api npx prisma generate
```

### Docker Production

```bash
# Required environment variables (export them or create a root .env file):
#   DATABASE_URL, DIRECT_URL, JWT_ACCESS_SECRET, CORS_ALLOWED_ORIGINS
# Optional: TRUST_PROXY (default 1), SUPPORT_EMAIL, GOOGLE_WEB_CLIENT_ID,
#           ACCESS_TOKEN_TTL_MINUTES, REFRESH_TOKEN_TTL_DAYS, LOG_LEVEL.
#
# The api and worker services wait for the one-shot `migrate` service to apply
# Prisma migrations before starting.
docker compose -f docker-compose.yml up -d --build

# Public legal pages served by the API:
#   /privacy            - privacy policy (required by Google Play)
#   /account-deletion   - account deletion instructions (required by Google Play)
```

## Project Structure

```
kasyaba/
├── kasyaba-app/              # Flutter application
│   └── lib/
│       ├── app/              # App config, router, theme
│       ├── core/             # API client, auth, storage
│       ├── features/         # Feature modules
│       └── shared/           # Shared models & widgets
├── kasyaba-backend/          # Express API & worker
│   ├── prisma/               # Schema & migrations
│   └── src/
│       ├── config/           # Environment, database
│       ├── lib/              # Utilities (decimal, dates)
│       ├── middleware/       # Auth, validation, errors
│       ├── modules/          # Feature modules
│       ├── jobs/             # Scheduled jobs
│       └── routes/           # Route registration
├── docs/                     # Documentation
└── docker-compose.yml        # Local orchestration
```

## API Endpoints

All routes are versioned under `/api/v1`.

### Authentication
- `POST /api/v1/auth/register` - Create account
- `POST /api/v1/auth/login` - Sign in
- `POST /api/v1/auth/google` - Google Sign-In
- `POST /api/v1/auth/refresh` - Refresh tokens
- `POST /api/v1/auth/logout` - Sign out
- `POST /api/v1/auth/logout-all` - Sign out all sessions
- `GET /api/v1/auth/me` - Get current user
- `PATCH /api/v1/auth/me` - Update profile and payday settings

### Accounts
- `GET /api/v1/accounts` - List accounts
- `POST /api/v1/accounts` - Create account
- `PATCH /api/v1/accounts/:id` - Update account
- `POST /api/v1/accounts/:id/archive` - Archive account
- `GET /api/v1/accounts/:id/balance` - Get balance

### Income
- `GET /api/v1/income` - List income (paginated)
- `POST /api/v1/income` - Add income
- `GET /api/v1/income/:id` - Get income
- `PATCH /api/v1/income/:id` - Update income
- `DELETE /api/v1/income/:id` - Delete income

### Expenses
- `GET /api/v1/expenses` - List expenses (paginated)
- `POST /api/v1/expenses` - Add expense
- `GET /api/v1/expenses/:id` - Get expense
- `PATCH /api/v1/expenses/:id` - Update expense
- `DELETE /api/v1/expenses/:id` - Delete expense
- `GET /api/v1/expenses/summary/by-category` - Category summary

### Categories
- `GET /api/v1/expense-categories` - List categories
- `POST /api/v1/expense-categories` - Create category
- `PATCH /api/v1/expense-categories/:id` - Update category
- `POST /api/v1/expense-categories/:id/archive` - Archive category

### Budgets
- `GET /api/v1/budgets` - List budgets
- `POST /api/v1/budgets` - Create budget
- `PATCH /api/v1/budgets/:id` - Update budget
- `DELETE /api/v1/budgets/:id` - Delete budget
- `GET /api/v1/budgets/status?month=YYYY-MM` - Budget status

### Savings Goals
- `GET /api/v1/goals` - List goals
- `POST /api/v1/goals` - Create goal
- `GET /api/v1/goals/:id` - Get goal
- `PATCH /api/v1/goals/:id` - Update goal
- `POST /api/v1/goals/:id/contributions` - Add contribution
- `DELETE /api/v1/goals/:id/contributions/:contributionId` - Remove contribution
- `GET /api/v1/goals/:id/progress` - Get progress

### Bills
- `GET /api/v1/bill-templates` - List bill templates
- `POST /api/v1/bill-templates` - Create bill template
- `PATCH /api/v1/bill-templates/:id` - Update template
- `POST /api/v1/bill-templates/:id/archive` - Archive template
- `GET /api/v1/bills` - List bill instances
- `POST /api/v1/bills/:id/mark-paid` - Mark bill paid
- `POST /api/v1/bills/:id/mark-unpaid` - Mark bill unpaid
- `POST /api/v1/bills/:id/cancel` - Cancel bill

### Alerts
- `GET /api/v1/alerts` - List alerts
- `GET /api/v1/alerts/analysis` - Get recovery analysis
- `POST /api/v1/alerts/:id/read` - Mark alert read
- `POST /api/v1/alerts/:id/dismiss` - Dismiss alert
- `POST /api/v1/alerts/read-all` - Mark all read

### Dashboard
- `GET /api/v1/dashboard` - Dashboard with forecasts
- `POST /api/v1/forecasting/purchase-check` - Evaluate purchase affordability

### Health
- `GET /health/live` - Liveness check
- `GET /health/ready` - Readiness check

## Testing

### Backend

```bash
cd kasyaba-backend
npm test              # Run unit tests
npm run test:watch    # Watch mode
npm run test:coverage # With coverage
```

### Flutter

```bash
cd kasyaba-app
flutter test
```

## Worker

The worker runs scheduled jobs for forecasting and bill generation:

```bash
cd kasyaba-backend
npm run start:worker
```

## License

MIT
