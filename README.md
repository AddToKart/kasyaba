# KASYABA

Personal financial tracker for Android and iOS with income and expense tracking, savings goals, bill reminders, explainable financial forecasting, predictive alerts, and a financial health score.

## Tech Stack

- **Mobile**: Flutter (Android & iOS)
- **API**: Express.js with TypeScript
- **Database**: PostgreSQL (via Supabase)
- **ORM**: Prisma
- **Auth**: JWT + refresh tokens, Google Sign-In

## Getting Started

### Prerequisites

- Flutter SDK ^3.12.2
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

### Docker Deployment

```bash
# Start all services (PostgreSQL, API, Worker)
docker-compose up -d
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
- `POST /api/v1/alerts/:id/read` - Mark alert read
- `POST /api/v1/alerts/:id/dismiss` - Dismiss alert
- `POST /api/v1/alerts/read-all` - Mark all read

### Dashboard
- `GET /api/v1/dashboard` - Dashboard with forecasts

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
