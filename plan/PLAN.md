# KASYABA — Enhanced Development Plan

> Personal financial tracker for Android and iOS with income and expense tracking, savings goals, bill reminders, explainable financial forecasting, predictive alerts, and a financial health score.

## 1. Product Vision

KASYABA helps users understand not only **where their money went**, but also **what is likely to happen next**. Its main value is an explainable prediction system that warns users about possible budget overruns, low balances, overdue bills, and delayed savings goals without relying on generative AI or opaque machine-learning models.

### 1.1 Primary Goals

- Make daily financial tracking fast and simple.
- Give users an accurate summary of their current financial position.
- Forecast near-term financial risks using understandable formulas.
- Remind users about bills before they become overdue.
- Show measurable progress toward savings goals.
- Keep all calculations auditable and defensible for a capstone or thesis panel.

### 1.2 Target Users

- Students and young professionals managing personal allowances or salaries.
- Users who want a lightweight alternative to complex accounting software.
- Users primarily working with Philippine pesos and recurring monthly obligations.

### 1.3 MVP Scope

The first release will include:

- Email/password registration and login.
- Google Sign-In.
- Income and expense CRUD operations.
- Default and custom expense categories.
- Savings goals and contribution history.
- Bills, recurring bills, and local reminders.
- Dashboard summaries and charts.
- Daily financial snapshots.
- Budget overrun, low-balance, savings-goal, and month-end forecasts.
- Financial health score.
- User-configurable alert thresholds and reminder lead times.

### 1.4 Explicit Non-Goals for the MVP

- Bank account synchronization.
- Cryptocurrency or investment portfolio tracking.
- Shared family accounts.
- Full accounting features such as journals, ledgers, or tax reports.
- Web application support.
- Generative AI advice.
- Multi-currency conversion.

---

## 2. Recommended Architecture

```text
Flutter Mobile App
        |
        | HTTPS + JSON REST API
        v
Express.js API
        |
        +-- Authentication and authorization
        +-- Business rules and validation
        +-- Financial calculations and forecasting
        +-- Scheduled jobs
        +-- Notification event generation
        |
        v
Supabase PostgreSQL
        |
        +-- Application data
        +-- Financial snapshots
        +-- Refresh-token sessions
        +-- Job and audit records
```

### 2.1 Technology Decisions

| Layer | Recommended Choice | Reason |
|---|---|---|
| Mobile app | Flutter | One codebase for Android and iOS; no web build required |
| API | Express.js with TypeScript | Familiar Node ecosystem with stronger type safety than plain JavaScript |
| Database | Supabase PostgreSQL | Managed PostgreSQL used through a normal connection string; Supabase Auth is not used |
| ORM | Prisma | Type-safe queries, migrations, schema visibility, and good developer tooling |
| Authentication | Express-owned auth | Avoids maintaining both Supabase Auth and a separate API auth layer |
| Access tokens | Short-lived JWT | Efficient authorization for normal API calls |
| Refresh tokens | Rotating opaque tokens stored hashed in PostgreSQL | Safer long-lived sessions and supports logout/revocation |
| Google login | Flutter `google_sign_in` + backend token verification | Better mobile experience than browser redirect-based Passport OAuth |
| Forecasting | Deterministic Node/TypeScript formulas | Explainable, testable, and appropriate for a thesis defense |
| Scheduled work | Dedicated worker process using `node-cron` initially | Keeps prediction calculations outside normal HTTP request latency |
| Deployment | Docker on Coolify or Dokploy | Continuous backend process, worker support, HTTPS, logs, and repeatable deployment |

### 2.2 Important Architecture Improvement: Separate API and Worker

Do not run the prediction job inside every API replica without protection. Use two process roles from the same codebase:

```text
api     -> serves REST requests
worker  -> runs scheduled forecasting and recurring-item jobs
```

For the MVP, both can use the same Docker image with different startup commands. This prevents duplicate cron execution when the API is scaled to multiple instances.

Example commands:

```json
{
  "scripts": {
    "start:api": "node dist/server.js",
    "start:worker": "node dist/worker.js"
  }
}
```

### 2.3 Repository Structure

KASYABA will use the existing monorepo layout: one root repository with two primary application folders.

```text
kasyaba/
├── kasyaba-app/                    # Flutter Android/iOS application
│   ├── android/
│   ├── ios/
│   ├── assets/
│   ├── lib/
│   ├── test/
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── kasyaba-backend/                # Express TypeScript API and worker
│   ├── prisma/
│   │   ├── migrations/
│   │   └── schema.prisma
│   ├── src/
│   ├── tests/
│   ├── Dockerfile
│   ├── package.json
│   └── tsconfig.json
├── docs/
│   ├── architecture.md
│   ├── api.md
│   └── forecasting.md
├── scripts/                        # Optional repository-wide helper scripts
├── docker-compose.yml              # Local backend/database orchestration
├── .github/
│   └── workflows/
│       ├── app-ci.yml
│       └── backend-ci.yml
├── .gitignore
├── README.md
└── PLAN.md
```

The two applications remain independently buildable. The Flutter project manages its dependencies through `pubspec.yaml`, while the Express project manages its dependencies through `package.json`. The root repository coordinates documentation, CI, Docker Compose, and shared development commands without forcing both projects into the same package manager workspace.

Recommended Express structure:

```text
kasyaba-backend/src/
├── config/
├── middleware/
├── modules/
│   ├── auth/
│   ├── users/
│   ├── accounts/
│   ├── income/
│   ├── expenses/
│   ├── categories/
│   ├── budgets/
│   ├── goals/
│   ├── bills/
│   ├── alerts/
│   ├── dashboard/
│   └── forecasting/
├── jobs/
├── lib/
├── routes/
├── app.ts
├── server.ts
└── worker.ts
```

Recommended Flutter structure:

```text
kasyaba-app/lib/
├── app/
│   ├── app.dart
│   ├── router.dart
│   └── theme/
├── core/
│   ├── config/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   └── utils/
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── transactions/
│   ├── budgets/
│   ├── goals/
│   ├── bills/
│   ├── alerts/
│   └── settings/
├── shared/
│   ├── models/
│   └── widgets/
└── main.dart
```

### 2.4 Monorepo Development Rules

- Run Flutter commands from `kasyaba-app/`.
- Run Node, Prisma, test, and migration commands from `kasyaba-backend/`.
- Keep backend-only secrets in `kasyaba-backend/.env`; never place them in the Flutter project.
- Store only non-secret mobile configuration through Flutter build-time configuration.
- Keep API contracts documented in `docs/api.md` or generated from the backend OpenAPI specification.
- Avoid manually duplicating backend TypeScript models inside Flutter. Define stable JSON request/response contracts and generate Dart clients later if the API becomes large.
- Configure CI path filters so Flutter CI runs for changes under `kasyaba-app/**`, while backend CI runs for `kasyaba-backend/**`, Prisma files, and deployment files.
- Deploy only `kasyaba-backend/` to Coolify or Dokploy. The Flutter application is built separately as an Android APK/App Bundle or iOS archive.

---

## 3. Backend Stack

### 3.1 Core Packages

| Purpose | Package | Notes |
|---|---|---|
| Runtime and language | Node.js LTS + TypeScript | Use strict TypeScript settings |
| Web framework | `express` | REST API |
| ORM and migrations | `prisma`, `@prisma/client` | Use migrations in source control |
| Validation | `zod` | Validate params, query strings, bodies, and environment variables |
| Password hashing | `argon2` | Preferred over bcrypt for a new system; bcrypt remains acceptable if required |
| JWT signing | `jose` | Modern JWT/JWK support; `jsonwebtoken` is also acceptable |
| Google verification | `google-auth-library` | Verify the Google ID token server-side |
| Precise money calculations | `decimal.js` | Never perform currency calculations with native floating-point arithmetic |
| Statistics | `simple-statistics` | Rolling averages, standard deviation, and optional linear regression |
| Scheduling | `node-cron` | Adequate for one dedicated worker instance |
| Logging | `pino`, `pino-http` | Structured logs suitable for production |
| API security | `helmet`, `cors`, `express-rate-limit` | Baseline HTTP hardening |
| Request IDs | `express-request-id` or custom middleware | Trace a request through logs |
| Testing | `vitest`, `supertest` | Unit and API integration testing |
| API documentation | `@asteasolutions/zod-to-openapi` or `swagger-jsdoc` | Generate an OpenAPI specification |

### 3.2 Environment Variables

```env
NODE_ENV=development
PORT=3000
DATABASE_URL=postgresql://...
DIRECT_URL=postgresql://...
JWT_ACCESS_SECRET=replace-me
ACCESS_TOKEN_TTL_MINUTES=15
REFRESH_TOKEN_TTL_DAYS=30
GOOGLE_WEB_CLIENT_ID=...
CORS_ALLOWED_ORIGINS=
LOG_LEVEL=info
WORKER_TIMEZONE=Asia/Manila
SNAPSHOT_CRON=10 0 * * *
```

Rules:

- Commit `.env.example`, never `.env`.
- Validate all variables on startup with Zod.
- Use different secrets for development, staging, and production.
- Store secrets in Coolify/Dokploy environment settings.

---

## 4. Authentication and Session Design

### 4.1 Supported Login Methods

- Email and password.
- Google Sign-In through the native Flutter flow.

Both methods resolve to the same internal user model and produce the same application session.

### 4.2 Recommended Token Flow

1. User authenticates using email/password or Google.
2. API issues:
   - A short-lived access JWT, recommended lifetime: 15 minutes.
   - A long-lived refresh token, recommended lifetime: 30 days.
3. Flutter stores both in `flutter_secure_storage`.
4. `dio` attaches the access token to API requests.
5. On a `401 TOKEN_EXPIRED`, the client calls `/auth/refresh` once.
6. The API rotates the refresh token and invalidates the old token.
7. Logout revokes the active refresh-token record.

This is safer than issuing one long-lived JWT that cannot be reliably revoked.

### 4.3 Authentication Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| POST | `/api/v1/auth/register` | Create an email/password user |
| POST | `/api/v1/auth/login` | Authenticate email/password |
| POST | `/api/v1/auth/google` | Verify Google ID token and find/create user |
| POST | `/api/v1/auth/refresh` | Rotate refresh token and issue new access token |
| POST | `/api/v1/auth/logout` | Revoke the active session |
| POST | `/api/v1/auth/logout-all` | Revoke all user sessions |
| GET | `/api/v1/auth/me` | Return authenticated user profile |

### 4.4 Account-Linking Rules

- Normalize emails to lowercase before storage.
- Require a unique email address.
- Store Google subject ID (`sub`) as the external Google identifier.
- When a Google login uses an email already registered locally, link it only after verification and according to a documented safe rule.
- Never trust a user ID sent in a request body; derive ownership from the authenticated access token.

### 4.5 Password Security

- Minimum 8 characters for the MVP; encourage 12 or more.
- Hash with Argon2id.
- Never log passwords, tokens, or full authorization headers.
- Apply stronger rate limits to login, registration, refresh, and Google-auth endpoints.

---

## 5. Flutter Application Stack

| Purpose | Recommended Package | Notes |
|---|---|---|
| HTTP | `dio` | Interceptors for tokens, refresh, retry, and request IDs |
| State management | `flutter_riverpod` | Feature-oriented and testable state management |
| Routing | `go_router` | Auth guards and predictable navigation |
| Models | `freezed` + `json_serializable` | Immutable typed DTOs and JSON parsing |
| Google login | `google_sign_in` | Native Google authentication |
| Secure storage | `flutter_secure_storage` | Access and refresh tokens |
| Local database/cache | `drift` or `isar` | Cached dashboard and offline transaction queue |
| Connectivity | `connectivity_plus` | Detect likely connectivity changes; API failures remain the source of truth |
| Charts | `fl_chart` | Trends and category charts |
| Notifications | `flutter_local_notifications`, `timezone` | Local bill reminders |
| Calendar | `table_calendar` | Bill calendar |
| Forms | `reactive_forms` | Consistent validation for financial forms |
| Formatting | `intl` | PHP and date formatting |
| Theming | Material 3 + `flex_color_scheme` | Consistent visual system |
| Error reporting | Optional Sentry Flutter SDK | Add after MVP core flows are stable |

### 5.1 Recommended Flutter Feature Structure

```text
lib/
├── app/
│   ├── router/
│   ├── theme/
│   └── bootstrap/
├── core/
│   ├── api/
│   ├── auth/
│   ├── database/
│   ├── errors/
│   ├── formatting/
│   └── widgets/
├── features/
│   ├── onboarding/
│   ├── dashboard/
│   ├── transactions/
│   ├── budgets/
│   ├── savings/
│   ├── bills/
│   ├── alerts/
│   └── settings/
└── main.dart
```

### 5.2 Offline and Poor-Connection Behavior

Even though the backend is authoritative, the mobile app should remain usable during temporary network loss.

MVP offline behavior:

- Cache the last dashboard response locally.
- Cache recent transactions, bills, goals, and categories.
- Allow users to create income and expense entries offline.
- Save offline mutations in an `outbox` queue with a client-generated UUID.
- Sync queued mutations when connectivity returns.
- Use an idempotency key so retrying a request cannot create duplicate transactions.
- Display a clear `Pending sync` state.

Conflict policy for the MVP:

- Server wins for edits to the same record.
- Offline-created records are inserted once through their client-generated UUID.
- Deletes are not queued in the earliest MVP unless tested thoroughly.

---

## 6. Data Model

### 6.1 Money Storage Rule

Store currency values as PostgreSQL `NUMERIC(14,2)` or as integer centavos. Do not use `FLOAT` or `DOUBLE PRECISION` for money.

The application will initially support PHP only, but every financial table should still have a `currency_code` field defaulting to `PHP` to avoid a painful future migration.

### 6.2 Core Tables

#### `users`

- `id` UUID primary key
- `email` unique, normalized
- `password_hash` nullable for Google-only accounts
- `google_subject` unique nullable
- `display_name`
- `avatar_url` nullable
- `timezone` default `Asia/Manila`
- `currency_code` default `PHP`
- `minimum_balance_threshold` default `0.00`
- `created_at`, `updated_at`, `last_login_at`

#### `auth_sessions`

- `id` UUID
- `user_id`
- `refresh_token_hash`
- `device_name` nullable
- `expires_at`
- `revoked_at` nullable
- `created_at`, `last_used_at`

#### `financial_accounts`

Even if the MVP initially shows one total balance, introducing accounts now prevents confusion between cash, e-wallets, and bank balances.

- `id`
- `user_id`
- `name` such as Cash, GCash, Maya, Bank
- `type` enum: `cash`, `bank`, `ewallet`, `other`
- `opening_balance`
- `currency_code`
- `is_archived`
- timestamps

#### `income_entries`

- `id`
- `user_id`
- `account_id`
- `amount`
- `source`
- `received_at`
- `notes` nullable
- `recurring_template_id` nullable
- `client_mutation_id` unique nullable
- timestamps

#### `expense_categories`

- `id`
- `user_id` nullable for system defaults
- `name`
- `icon_key`
- `is_archived`
- unique constraint appropriate to user/system ownership

#### `expense_entries`

- `id`
- `user_id`
- `account_id`
- `category_id`
- `amount`
- `description`
- `spent_at`
- `notes` nullable
- `recurring_template_id` nullable
- `client_mutation_id` unique nullable
- timestamps

#### `budgets`

Budgets should be explicit entities instead of being hidden inside forecasting logic.

- `id`
- `user_id`
- `category_id` nullable for an overall budget
- `period` enum initially `monthly`
- `amount`
- `starts_on`
- `ends_on` nullable
- `is_active`
- timestamps

#### `savings_goals`

- `id`
- `user_id`
- `name`
- `target_amount`
- `target_date` nullable
- `status` enum: `active`, `completed`, `paused`, `cancelled`
- timestamps

Do not store a manually editable `current_amount`. Derive it from contributions or maintain it only as a transactionally updated cached value.

#### `savings_contributions`

- `id`
- `goal_id`
- `user_id`
- `account_id` nullable
- `amount`
- `contributed_at`
- `notes` nullable
- timestamps

#### `bill_templates`

Defines the recurring rule.

- `id`
- `user_id`
- `name`
- `default_amount`
- `category_id` nullable
- `recurrence` enum: `none`, `weekly`, `monthly`
- `day_of_week` nullable
- `day_of_month` nullable
- `starts_on`
- `ends_on` nullable
- `reminder_lead_days`
- `is_active`
- timestamps

#### `bill_instances`

Represents actual payable occurrences, avoiding the ambiguity of one row whose due date keeps changing.

- `id`
- `user_id`
- `template_id` nullable
- `name`
- `amount`
- `due_date`
- `status` enum: `upcoming`, `paid`, `overdue`, `cancelled`
- `paid_at` nullable
- `expense_entry_id` nullable
- timestamps

#### `financial_snapshots`

- `id`
- `user_id`
- `snapshot_date`
- `actual_balance`
- `income_month_to_date`
- `expenses_month_to_date`
- `savings_month_to_date`
- `projected_month_end_income`
- `projected_month_end_expenses`
- `predicted_month_end_balance`
- `health_score`
- `health_grade`
- `calculation_version`
- `calculation_details` JSONB
- `created_at`
- unique `(user_id, snapshot_date)`

The `calculation_details` field should retain important inputs and intermediate values so forecasts can be explained and audited.

#### `financial_alerts`

- `id`
- `user_id`
- `snapshot_id` nullable
- `type` enum
- `severity` enum: `info`, `warning`, `critical`
- `title`
- `message`
- `reason_data` JSONB
- `effective_date`
- `deduplication_key`
- `read_at` nullable
- `dismissed_at` nullable
- `resolved_at` nullable
- timestamps

#### `job_runs`

- `id`
- `job_name`
- `started_at`
- `finished_at` nullable
- `status`
- `processed_count`
- `failed_count`
- `error_summary` nullable

### 6.3 Required Indexes

At minimum:

- Every foreign key.
- `(user_id, received_at)` for income.
- `(user_id, spent_at)` for expenses.
- `(user_id, due_date, status)` for bills.
- `(user_id, snapshot_date desc)` for snapshots.
- `(user_id, read_at, created_at desc)` for alerts.
- Unique index on `client_mutation_id` where not null.

### 6.4 Ownership and Deletion Rules

- Every user-owned query must include `user_id` from the authenticated session.
- Use soft deletion or archiving for categories, accounts, goals, and recurring templates when historical records depend on them.
- Deleting a user should follow a documented cascade/anonymization policy.

---

## 7. Functional Modules and API Surface

All routes are versioned under `/api/v1`.

### 7.1 Accounts

- `GET /accounts`
- `POST /accounts`
- `PATCH /accounts/:id`
- `POST /accounts/:id/archive`
- `GET /accounts/:id/balance`

### 7.2 Income

- `GET /income?from=&to=&source=&accountId=&page=&limit=`
- `POST /income`
- `GET /income/:id`
- `PATCH /income/:id`
- `DELETE /income/:id`

### 7.3 Expenses

- `GET /expenses?from=&to=&categoryId=&accountId=&search=&page=&limit=`
- `POST /expenses`
- `GET /expenses/:id`
- `PATCH /expenses/:id`
- `DELETE /expenses/:id`
- `GET /expenses/summary/by-category?from=&to=`

### 7.4 Categories

- `GET /expense-categories`
- `POST /expense-categories`
- `PATCH /expense-categories/:id`
- `POST /expense-categories/:id/archive`

Seed defaults such as Food, Transportation, Utilities, Rent, Education, Healthcare, Entertainment, Shopping, and Other.

### 7.5 Budgets

- `GET /budgets`
- `POST /budgets`
- `PATCH /budgets/:id`
- `DELETE /budgets/:id`
- `GET /budgets/status?month=YYYY-MM`

### 7.6 Savings Goals

- `GET /goals`
- `POST /goals`
- `GET /goals/:id`
- `PATCH /goals/:id`
- `POST /goals/:id/contributions`
- `DELETE /goals/:id/contributions/:contributionId`
- `GET /goals/:id/progress`

Progress response should include:

- Total contributed.
- Percentage complete.
- Remaining amount.
- Average monthly contribution.
- Forecast completion date.
- Whether the target date is currently achievable.

### 7.7 Bills

- `GET /bills?status=&from=&to=`
- `POST /bill-templates`
- `PATCH /bill-templates/:id`
- `POST /bill-templates/:id/archive`
- `POST /bills/:id/mark-paid`
- `POST /bills/:id/mark-unpaid`
- `POST /bills/:id/cancel`

When a bill is marked paid, the operation may optionally create a corresponding expense in one database transaction.

### 7.8 Alerts

- `GET /alerts?status=unread&type=&severity=`
- `POST /alerts/:id/read`
- `POST /alerts/:id/dismiss`
- `POST /alerts/read-all`

### 7.9 Dashboard

`GET /dashboard?period=month`

Recommended response:

```json
{
  "asOf": "2026-07-25T00:00:00+08:00",
  "balance": "12500.00",
  "income": "25000.00",
  "expenses": "9800.00",
  "savings": "2500.00",
  "budgetUsedPercent": 65.3,
  "predictedMonthEndBalance": "4800.00",
  "healthScore": 74,
  "healthGrade": "Good",
  "upcomingBills": [],
  "goals": [],
  "alerts": [],
  "charts": {
    "dailyBalance": [],
    "expensesByCategory": []
  }
}
```

The dashboard should read the latest snapshot but may combine it with fresh same-day totals so a newly entered transaction appears immediately.

---

## 8. Forecasting and Predictive Alert Engine

### 8.1 Design Principles

- Deterministic and explainable.
- All money calculations use `Decimal`.
- Every formula is unit tested.
- Insufficient data produces a low-confidence or unavailable result, not a fabricated prediction.
- Store the formula version and major inputs with every snapshot.
- Forecasts are guidance, not guarantees.

### 8.2 Daily Worker Pipeline

For each active user:

1. Load user preferences, accounts, active budgets, recurring income, bill instances, recent expenses, and goal contributions.
2. Calculate actual current balance.
3. Calculate month-to-date totals.
4. Project income and expenses through month end.
5. Calculate projected balances across important future dates.
6. Calculate savings-goal forecasts.
7. Calculate financial health score.
8. Upsert the daily snapshot.
9. Generate, update, resolve, or deduplicate alerts.
10. Record success/failure in `job_runs`.

Also recalculate a user's snapshot after important mutations such as adding an expense or marking a large bill paid. This can run asynchronously, but the daily worker remains the safety net.

### 8.3 Expense Projection

Avoid using only one simplistic method. Use a clear fallback hierarchy:

1. If at least 60 days of history exist, use a weighted average of the last three complete months.
2. If 30–59 days exist, use the daily average multiplied by remaining days.
3. If fewer than 30 days exist, use month-to-date pace with a visible `limited history` confidence label.
4. Add known unpaid bill instances separately so regular expenses and contractual bills are not double-counted.

Suggested weighted monthly estimate:

```text
historical_monthly_expense =
    latest_complete_month × 0.50
  + previous_month        × 0.30
  + third_month           × 0.20
```

Suggested month-to-date pace:

```text
average_daily_spend = month_to_date_expenses / elapsed_days
projected_variable_expenses = average_daily_spend × days_in_month
```

Cap or flag abnormal outliers when one transaction is far outside the user's normal range. Do not silently discard it; include the decision in `calculation_details`.

### 8.4 Expected Income

Expected income should come from:

- Actual income already received this month.
- Active recurring-income templates whose next occurrence is before the forecast date.
- Optional manually configured next-pay date and expected amount.

Do not infer a salary date from one or two historical entries. Require either a recurring rule or sufficient repeat history.

### 8.5 Projected Balance

For a future date `t`:

```text
projected_balance(t) =
    current_actual_balance
  + expected_income_between(now, t)
  - projected_variable_expenses_between(now, t)
  - unpaid_known_bills_due_between(now, t)
  - planned_savings_contributions_between(now, t)
```

Known bills must not also remain inside projected variable spending if they were already counted in the historical baseline. Document the chosen treatment to prevent double counting.

### 8.6 Budget Overrun Alert

Trigger when either condition is true:

```text
projected_month_end_spend > active_budget
```

or

```text
month_to_date_spend / elapsed_days
> budget / days_in_month × tolerance_factor
```

Suggested severities:

- `info`: projected 90–100% of budget.
- `warning`: projected 100–115%.
- `critical`: projected above 115%.

### 8.7 Low-Balance Alert

Evaluate projected balance on:

- Every upcoming bill due date.
- The next expected income date.
- End of month.

Trigger when the minimum projected balance drops below the user's configured threshold.

The alert should state:

- The projected lowest balance.
- The date it may occur.
- The major bills or expenses contributing to it.
- The forecast confidence.

### 8.8 Savings Goal Forecast

```text
average_monthly_contribution = rolling average of monthly contributions
remaining_amount = target_amount - total_contributed
months_remaining = remaining_amount / average_monthly_contribution
```

Edge cases:

- Goal already completed: mark complete.
- No contribution history: no completion forecast.
- Zero or negative average: show `No active saving pace`.
- Target date exists: calculate required monthly contribution and compare it with current pace.

### 8.9 Financial Health Score

Use normalized sub-scores from 0 to 100:

#### Savings score — 30%

```text
savings_rate = savings_this_month / income_this_month
```

Suggested mapping:

- 20% or more = 100.
- 10–19.99% = 70–99.
- 1–9.99% = 30–69.
- 0% = 0.

#### Budget score — 30%

Measures adherence to the active overall budget.

- At or below 90% projected usage = 100.
- 90–100% = 70–99.
- 100–115% = 30–69.
- Above 115% = 0–29.

#### Bill reliability score — 20%

Based on the percentage of bill instances paid on or before their due date over the trailing three months.

#### Balance resilience score — 20%

Based on whether projected balance remains above the configured minimum through the forecast horizon.

```text
health_score =
    savings_score × 0.30
  + budget_score × 0.30
  + bill_score × 0.20
  + resilience_score × 0.20
```

Suggested grades:

- 85–100: Excellent.
- 70–84: Good.
- 50–69: Fair.
- 0–49: Needs Attention.

The UI must show the score breakdown, not only the final number.

### 8.10 Forecast Confidence

Each forecast should include `high`, `medium`, or `low` confidence.

Example rules:

- High: at least 90 days of consistent data plus configured recurring income.
- Medium: 30–89 days of data.
- Low: fewer than 30 days, missing salary schedule, or highly irregular spending.

### 8.11 Alert Deduplication

Create a stable key such as:

```text
userId:type:effectivePeriod:primaryEntityId
```

Do not create a new unread copy of the same alert every day. Update the existing active alert when its predicted amount changes and resolve it when the risk disappears.

---

## 9. Bill Reminder Strategy

### 9.1 Local Notifications

The Flutter app schedules local reminders because they work even when the backend is unavailable.

- Default lead time: 1 day before.
- Optional same-day reminder.
- Reschedule notifications whenever a bill is created, edited, paid, or cancelled.
- Use timezone-aware local dates.
- Rebuild upcoming schedules when the app starts or the timezone changes.

### 9.2 Server-Side Reminder Events

The backend should still track due and overdue status. In a future phase, this allows push notifications through Firebase Cloud Messaging without redesigning bill data.

### 9.3 Recurring Bill Generation

The worker should generate bill instances ahead of time, for example 60 days into the future. Use a uniqueness constraint on `(template_id, due_date)` so the job is idempotent.

---

## 10. API Standards

### 10.1 Response Envelope

Successful collection response:

```json
{
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 0
  }
}
```

Error response:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request contains invalid fields.",
    "fields": {
      "amount": "Amount must be greater than zero."
    },
    "requestId": "..."
  }
}
```

### 10.2 Conventions

- Use ISO 8601 timestamps.
- Return monetary values as strings in JSON to preserve decimal precision.
- Use `YYYY-MM-DD` for date-only fields such as bill due dates.
- Paginate transaction lists.
- Limit maximum page size.
- Use consistent machine-readable error codes.
- Accept `Idempotency-Key` for transaction-creation endpoints.
- Generate OpenAPI documentation and keep it in CI.

---

## 11. Security and Privacy Requirements

### 11.1 API Security

- HTTPS only in production.
- Strict CORS configuration; mobile clients do not require permissive wildcard origins.
- `helmet` security headers.
- Body-size limits.
- Rate limits by IP and, when authenticated, by user.
- Zod validation before service logic.
- Parameterized ORM queries only.
- Generic login errors to avoid account enumeration.
- Request IDs and structured audit-safe logs.

### 11.2 Financial Data Privacy

- Collect only data needed for the product.
- Never log full transaction descriptions at info level in production.
- Never expose another user's records.
- Provide account deletion and data export in a later release, but design the schema so both are possible.
- Add a privacy notice explaining that forecasts are estimates based on user-entered data.

### 11.3 Database Security

- Use a dedicated restricted database user for the application.
- Do not expose the PostgreSQL port publicly unless absolutely necessary.
- Configure automated backups in Supabase.
- Test restoration before production launch.
- Use separate development and production databases.

### 11.4 Mobile Security

- Store tokens only in secure storage.
- Do not place secrets in the Flutter binary.
- The Google client ID is configuration, but backend secrets must never be bundled in the app.
- Clear sensitive state on logout.
- Obfuscation can be enabled for release builds, but it is not a substitute for server-side security.

---

## 12. Testing Strategy

### 12.1 Backend Unit Tests

Required coverage:

- Every forecasting formula.
- Financial health score boundaries.
- Recurrence date generation.
- Money rounding behavior.
- Refresh-token rotation.
- Ownership authorization.
- Alert deduplication.

Use fixed clocks in tests so month-end and timezone calculations are deterministic.

### 12.2 Backend Integration Tests

Test with a real temporary PostgreSQL database or isolated test schema:

- Register, login, refresh, logout.
- Google account find/create service with mocked token verification.
- Income and expense CRUD.
- Cross-user access rejection.
- Bill payment creating an expense transactionally.
- Snapshot job rerun producing no duplicates.
- Idempotency-key retries.

### 12.3 Flutter Tests

- Unit tests for repositories and notifiers.
- Widget tests for forms, dashboard states, and alerts.
- Integration tests for login, adding an expense, creating a goal, and marking a bill paid.
- Offline queue test: create offline, reconnect, sync once.

### 12.4 Forecast Validation Dataset

Create seeded scenarios with manually computed expected results:

1. Stable salaried user.
2. User with irregular income.
3. User with no financial history.
4. User near budget limit.
5. User whose balance becomes negative before salary.
6. User with a large one-time expense.
7. User with no savings contributions.
8. User completing a goal early.

Document expected input and output in `docs/forecasting.md`. This will be useful during thesis evaluation.

### 12.5 Quality Gates

A pull request should pass:

- Type checking.
- Linting and formatting.
- Unit tests.
- Integration tests.
- Prisma migration validation.
- Flutter analysis and tests.
- Docker image build.

---

## 13. Deployment and Operations

### 13.1 Production Services

Recommended Coolify/Dokploy setup:

| Service | Role |
|---|---|
| `kasyaba-api` | Express REST API |
| `kasyaba-worker` | Scheduled forecasting and recurrence jobs |
| Supabase PostgreSQL | Managed database |

Both backend services can use the same image but different commands.

### 13.2 Dockerfile Requirements

- Multi-stage build.
- Non-root runtime user.
- Production dependencies only in runtime stage.
- Health-check endpoint.
- Graceful shutdown on `SIGTERM`.

### 13.3 Health Endpoints

- `GET /health/live`: process is running.
- `GET /health/ready`: database connection and required dependencies are ready.

### 13.4 Database Migrations

- Run migrations as a controlled deployment step, not simultaneously from every replica.
- Back up before destructive migrations.
- Use additive migrations first, deploy compatible code, then remove old fields later.

### 13.5 Observability

Minimum production visibility:

- Structured JSON logs.
- Request duration and status.
- Worker run duration and failure count.
- Snapshot users processed.
- Database connection errors.
- Authentication failure rates.

Recommended later additions:

- Sentry for backend and Flutter crashes.
- Uptime monitoring for `/health/ready`.
- Alerts for repeated worker failures.

### 13.6 Backup and Recovery

- Confirm Supabase backup retention.
- Export a manual backup before major releases.
- Document restoration steps.
- Set a recovery objective appropriate to a student project, such as restoring within one day with no more than one day of data loss.

---

## 14. Development Environments

Use three environments where practical:

| Environment | Purpose |
|---|---|
| Local | Daily development with local or development PostgreSQL |
| Staging | Production-like deployment for QA and demonstrations |
| Production | Real user data |

Each environment must have:

- Separate database.
- Separate secrets.
- Separate Google OAuth configuration where required.
- Clearly labeled API base URL.

---

## 15. User Experience Plan

### 15.1 Main Navigation

Recommended bottom navigation:

1. Dashboard.
2. Transactions.
3. Add transaction.
4. Goals and bills.
5. Profile/settings.

### 15.2 Dashboard Priority

Display information in this order:

1. Current available balance.
2. Predicted month-end balance.
3. Important active alert.
4. Income, expenses, and savings totals.
5. Budget progress.
6. Upcoming bills.
7. Savings goals.
8. Trends and categories.

### 15.3 Explainable Alerts

Every alert should answer:

- What may happen?
- When may it happen?
- Why was it predicted?
- What numbers were used?
- How confident is the prediction?

Example:

> **Possible low balance on August 12**  
> Your projected balance may fall to **₱850** before your next expected income. This estimate includes **₱3,200** in upcoming bills and your recent average daily spending. Confidence: **Medium**.

Avoid prescriptive financial advice such as telling users to borrow money or make investments.

### 15.4 Empty and First-Use States

- Explain that forecasts improve after more transactions are recorded.
- Let users set their opening balance during onboarding.
- Ask for common recurring income and bills during setup.
- Show sample placeholders rather than blank charts.

---

## 16. Implementation Roadmap

### Phase 0 — Decisions and Setup

Deliverables:

- Confirm PHP-only MVP.
- Confirm account model and opening balance behavior.
- Confirm recurring-income setup.
- Define health-score weights and thresholds.
- Finalize the root monorepo with `kasyaba-app/` and `kasyaba-backend/`, then configure branching rules, project-specific formatters, linters, CI workflows, and environment examples.
- Create wireframes for all MVP screens.

Exit criteria:

- Architecture decisions documented.
- `kasyaba-backend` runs locally and `kasyaba-app` connects to its configured API base URL.
- CI passes on an empty scaffold.

### Phase 1 — Backend Foundation and Authentication

Deliverables:

- Express TypeScript scaffold.
- Prisma schema and initial migration.
- Error format, request IDs, logging, Zod validation.
- Register, login, refresh, logout, and `/me`.
- Google ID-token verification.
- Flutter auth screens and secure token handling.

Exit criteria:

- User can register, log in, close/reopen the app, refresh a session, and log out.
- Cross-user access tests pass.

### Phase 2 — Accounts and Transactions

Deliverables:

- Financial accounts.
- Income and expense CRUD.
- Default/custom categories.
- Transaction filters, pagination, and search.
- Flutter transaction history and forms.
- Local cache and offline creation queue.

Exit criteria:

- Totals remain correct after create/edit/delete.
- Offline-created records sync once without duplicates.

### Phase 3 — Budgets and Dashboard Foundation

Deliverables:

- Overall and category budgets.
- Monthly summary queries.
- Basic dashboard endpoint.
- Dashboard cards and charts.

Exit criteria:

- Dashboard matches manually calculated test data.

### Phase 4 — Savings Goals

Deliverables:

- Goal CRUD.
- Contribution logging.
- Progress and required-rate calculations.
- Goal charts and completion state.

Exit criteria:

- Goal total is always derivable from contribution history.

### Phase 5 — Bills and Reminders

Deliverables:

- Recurring bill templates.
- Bill-instance generation.
- Paid/overdue workflow.
- Optional expense creation when marked paid.
- Local notification scheduling and rescheduling.

Exit criteria:

- Re-running bill generation creates no duplicates.
- Notifications update correctly after bill changes.

### Phase 6 — Forecasting Engine

Deliverables:

- Versioned calculation service.
- Daily worker.
- Snapshot storage.
- Expense, income, balance, and goal forecasts.
- Confidence levels.
- Seeded validation scenarios.

Exit criteria:

- All formulas pass unit tests and seeded expected-result tests.
- Worker is idempotent.

### Phase 7 — Alerts and Health Score

Deliverables:

- Budget, low-balance, savings, bill, and month-end alerts.
- Alert deduplication and resolution.
- Health score and breakdown.
- Explainable alert UI.

Exit criteria:

- Same risk does not generate duplicate alerts.
- Score breakdown exactly reconciles with the final score.

### Phase 8 — Production Hardening

Deliverables:

- Docker deployment for API and worker.
- Staging environment.
- Backups and restore procedure.
- Health checks, structured logs, uptime monitor.
- Performance indexes and query review.
- Privacy notice and account deletion plan.

Exit criteria:

- Staging survives a full regression test.
- Worker failure is visible and recoverable.
- Database restore has been tested.

### Phase 9 — Release Preparation

Deliverables:

- Android release build.
- iOS configuration if in scope.
- App icon, splash screen, screenshots, and privacy disclosures.
- Demo dataset and presentation scenario.
- User guide and technical documentation.

Exit criteria:

- A new tester can install the app, complete onboarding, and use every core module without developer help.

---

## 17. Suggested Milestones

| Milestone | Result |
|---|---|
| M1 | Authenticated mobile shell and backend foundation |
| M2 | Complete transaction tracking with accounts and categories |
| M3 | Budgets and usable dashboard |
| M4 | Savings goals and bill reminders |
| M5 | Validated prediction engine and daily snapshots |
| M6 | Explainable alerts and health score |
| M7 | Staging deployment and production hardening |
| M8 | Final mobile release and capstone documentation |

---

## 18. Definition of Done

A feature is complete only when:

- Backend endpoint and validation are implemented.
- Ownership authorization is enforced.
- Database migration is included when necessary.
- Unit and integration tests pass.
- Flutter loading, success, empty, offline, and error states are handled.
- Accessibility labels are present for important controls.
- Logs contain enough context without exposing sensitive data.
- API documentation is updated.
- Acceptance criteria are demonstrated on staging.

---

## 19. Key Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Forecasts are misleading with little data | Add confidence levels and minimum-history rules |
| Money totals drift | Use PostgreSQL numeric fields and Decimal arithmetic |
| Duplicate scheduled work | Use a single worker plus idempotent upserts and uniqueness constraints |
| Duplicate offline transactions | Client UUID and `Idempotency-Key` support |
| Long-lived JWT compromise | Short access token plus rotating refresh token |
| Bill recurrence becomes inconsistent | Separate templates from generated bill instances |
| Forecast job slows the API | Separate API and worker processes |
| User distrusts score | Show full score breakdown and calculation explanations |
| Supabase connection limits | Use the recommended pooled connection for runtime and direct connection for migrations |
| Thesis scope becomes too large | Freeze MVP non-goals and defer optional modules |

---

## 20. Recommended Decisions for the Current Open Questions

1. **Currency:** Use PHP only in the MVP, but include `currency_code = PHP` in the schema.
2. **Next salary date:** Derive it from an explicit recurring-income rule. Offer a manual expected-income entry for irregular earners.
3. **Login providers:** Use email/password and Google only for the first Android release. Add Sign in with Apple only when iOS distribution requirements make it necessary.
4. **ORM:** Choose Prisma rather than keeping Prisma/Drizzle undecided.
5. **Password hashing:** Use Argon2id for a new implementation.
6. **Sessions:** Use short-lived JWT access tokens plus rotating refresh tokens.
7. **Balance model:** Add financial accounts and an opening balance rather than calculating one unexplained global balance.
8. **Recurring bills:** Separate recurring templates from bill instances.
9. **Scheduler:** Deploy one dedicated worker process rather than embedding unguarded cron logic in every API process.
10. **Offline support:** Include cached reads and offline transaction creation in the MVP, but postpone complex offline edits/deletes.

---

## 21. Future Enhancements After the MVP

- Firebase Cloud Messaging for remote alerts.
- CSV import/export.
- PDF monthly financial reports.
- Biometric app unlock.
- Shared household budgets.
- Receipt image attachments.
- Bank/e-wallet integration where legally and technically available.
- Additional currencies and exchange-rate support.
- More recurrence options.
- Anomaly detection using transparent statistical rules.
- User-controlled data export and complete account deletion workflow.
- Admin-only operational dashboard with no access to unnecessary financial details.

---

## 22. Final Recommended Build Sequence

```text
Architecture decisions
        ↓
Repository + CI + local environments
        ↓
Database + auth + session security
        ↓
Accounts + income + expenses + categories
        ↓
Budgets + initial dashboard
        ↓
Savings goals
        ↓
Bills + local reminders
        ↓
Worker + recurring generation
        ↓
Forecasting + snapshots
        ↓
Alerts + health score
        ↓
Offline resilience + polish
        ↓
Staging + testing + backups
        ↓
Release and capstone documentation
```

The most important implementation rule is to build and validate the financial data model first. The dashboard, health score, and predictive alerts should remain consumers of reliable transaction data rather than becoming separate sources of truth.
