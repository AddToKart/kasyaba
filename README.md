# 🌿 KASYABA

> **Personal Financial Runway & Intelligent Cash-Flow Tracker for Android**  
> Built with Flutter and an Express/TypeScript backend. Features include daily safe-to-spend allowances, savings goals with a "Can I Buy This?" simulator, bill timeline tracking, and predictive cash-flow forecasting.

---

## 🏗️ Architecture at a Glance

Kasyaba consists of two main projects in this repository:

```
kasyaba/
├── 📱 kasyaba-app/        # Flutter Android client (Riverpod, Material 3, Dark Luxury UI)
├── ⚙️ kasyaba-backend/    # Node.js / Express TypeScript API & Prisma ORM
└── 🐳 docker-compose.yml # Optional full-stack local container orchestration
```

* **Frontend:** Flutter (Dart) targeting Android.
* **Backend:** Express.js REST API with TypeScript, Prisma ORM, and Vitest test suite.
* **Database:** PostgreSQL (run locally via Docker or in the cloud via Supabase).
* **Auth:** JWT Access + Refresh Tokens, optional Google Sign-In.

---

## 📋 Prerequisites Checklist

Before you begin, make sure your computer has the following tools installed:

1. **Git**: [Download Git](https://git-scm.com/downloads)
2. **Node.js (LTS v20+)**: [Download Node.js](https://nodejs.org/)
   * Check installation: `node -v` and `npm -v`
3. **Flutter SDK (v3.44.x+)**: [Install Flutter](https://docs.flutter.dev/get-started/install)
   * Check installation: `flutter doctor`
4. **Android Studio**: [Download Android Studio](https://developer.android.com/studio)
   * Required for Android SDK, JDK, and setting up an Android Virtual Device (Emulator).
5. **Docker Desktop** *(Optional)*: [Download Docker](https://www.docker.com/)
   * Recommended if you want to run PostgreSQL locally without installing it manually.

---

## 🚀 Quick-Start Guide (Step-by-Step)

Follow these steps in order to get the entire project running on your machine.

---

### Step 1: Database & Backend API Setup

Open your terminal (PowerShell, Command Prompt, or Terminal) and enter the backend directory:

```bash
cd kasyaba-backend
```

#### 1.1 Create your `.env` configuration file
Copy the provided `.env.example` template:

* **On Windows (PowerShell or Command Prompt):**
  ```powershell
  copy .env.example .env
  ```
* **On macOS / Linux:**
  ```bash
  cp .env.example .env
  ```

#### 1.2 Configure your Database Connection
Open `.env` in your code editor. By default, it expects a local PostgreSQL database:
```ini
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/kasyaba
DIRECT_URL=postgresql://postgres:postgres@localhost:5432/kasyaba
```

> **💡 Beginner Tip (Choose Option A or Option B):**
> * **Option A (Local with Docker - Easiest):**
>   If you have Docker Desktop running, start a local Postgres database with one command:
>   ```bash
>   docker compose up -d postgres
>   ```
> * **Option B (Cloud with Supabase - Free):**
>   Create a free project at [supabase.com](https://supabase.com). Copy the transaction pooler URL (port `6543`) into `DATABASE_URL` and the direct session URL (port `5432`) into `DIRECT_URL`.

#### 1.3 Install dependencies
```bash
npm install
```

#### 1.4 Generate Prisma client & apply database migrations
This creates all tables (accounts, transactions, bills, goals, alerts) in your database:
```bash
npx prisma generate
npx prisma migrate dev
```

#### 1.5 Seed starter data (Default Categories)
```bash
npx tsx prisma/seed.ts
```

#### 1.6 Start the backend development server
```bash
npm run dev
```

🎉 **Success!** You should see:
```text
Server running on http://localhost:3000
```
You can verify it works by opening [http://localhost:3000/health/live](http://localhost:3000/health/live) in your browser. It should respond with `{"status":"ok"}`.

> ⚠️ **Keep this terminal window running!** Leave it open and proceed to Step 2 in a new terminal window.

---

### Step 2: Flutter Mobile App Setup

Open a **new** terminal window and navigate to `kasyaba-app`:

```bash
cd kasyaba-app
```

#### 2.1 Install Flutter dependencies
```bash
flutter pub get
```

#### 2.2 Start an Android Device or Emulator
* Open Android Studio ➔ **Virtual Device Manager** (Device Manager) ➔ click **Play** (▶) next to any Android device emulator (e.g. Pixel 8 with API 34/35).
* *Or*, connect your physical Android phone with USB Debugging enabled.

Check that Flutter detects your device:
```bash
flutter devices
```

#### 2.3 Run the mobile app!
```bash
flutter run
```

### 📱 How the App Connects to the Backend:
* **Android Emulator (Default):** The emulator cannot reach your computer via `localhost`. Instead, Android emulators use `http://10.0.2.2:3000`. **The app already defaults to this automatically in debug mode!** You don't need to configure anything.
* **Physical Android Phone (Over Wi-Fi):** If running on a physical phone connected via USB, point Flutter to your computer's local Wi-Fi IP address (e.g., `192.168.1.5`):
  ```bash
  flutter run --dart-define=API_BASE_URL=http://192.168.1.5:3000
  ```

---

## 🐳 Alternative: 1-Command Docker Setup

If you have Docker Desktop installed, you can launch the Postgres database, API, and background worker all together:

```bash
# From the root directory:
docker compose up --build
```

* Backend API will be live at: `http://localhost:3000`
* PostgreSQL will be running on port: `5432`
* Changes to backend code will hot-reload automatically inside the container.

---

## 🧪 Running Tests

Both frontend and backend include automated test suites to ensure everything works correctly.

### Run Backend Tests (Vitest)
```bash
cd kasyaba-backend
npm test              # Runs all 143 unit & e2e tests
npm run test:watch    # Re-runs tests on save
```

### Run Mobile App Tests (Flutter)
```bash
cd kasyaba-app
flutter test          # Runs all 21 unit & widget tests
dart analyze          # Checks for code style and type warnings
```

---

## 🛠️ Common Beginner Troubleshooting

<details>
<summary><b>1. App says "Connection timed out" or "Could not reach server" on Android</b></summary>

* **Are you using an Android Emulator?** The app automatically calls `http://10.0.2.2:3000`. Make sure your backend terminal is running (`npm run dev` in `kasyaba-backend`).
* **Are you using a Physical Phone?** A physical phone cannot reach `10.0.2.2` or `localhost`. Find your PC's IP address (`ipconfig` on Windows or `ifconfig` on Mac) and run:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://YOUR_COMPUTER_IP:3000
  ```
* **Firewall:** Ensure Windows Defender Firewall allows incoming connections on port 3000.
</details>

<details>
<summary><b>2. <code>npx prisma migrate dev</code> fails with database connection error</b></summary>

* Make sure your database is running! If using Docker, run `docker compose up -d postgres`.
* Check that the `DATABASE_URL` in `kasyaba-backend/.env` matches your database credentials and port (`5432`).
* If using Supabase, make sure your password is correct and your project is not paused.
</details>

<details>
<summary><b>3. <code>flutter run</code> fails with Android licenses or Gradle errors</b></summary>

* Open terminal and accept Android SDK licenses:
  ```bash
  flutter doctor --android-licenses
  ```
  Type `y` to accept all prompts.
* Run `flutter doctor` to ensure all checkmarks for Android Studio and SDK are green.
</details>

<details>
<summary><b>4. Port 3000 is already in use</b></summary>

* If another app is using port 3000, open `kasyaba-backend/.env` and change `PORT=3000` to `PORT=3001`.
* In `kasyaba-app`, run with:
  ```bash
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3001
  ```
</details>

---

## 📁 Repository Overview

```
kasyaba/
├── kasyaba-app/
│   ├── android/              # Native Android configuration
│   ├── lib/
│   │   ├── app/              # Navigation router & Luxury Dark Theme (AppColors)
│   │   ├── core/             # API clients, offline sync, auth tokens, currency formatters
│   │   ├── features/
│   │   │   ├── dashboard/    # Cash bridge, balance runway, month-end forecast
│   │   │   ├── planning/     # Daily safe-to-spend allowance, runway milestones & what-if simulator
│   │   │   ├── transactions/ # Incomes, expenses, transfers
│   │   │   ├── goals/        # Savings goals & "Can I Buy This?" card
│   │   │   ├── bills/        # Recurring bill reminders & payment markers
│   │   │   └── budgets/      # Category spending limits
│   │   └── shared/           # ModernCard, ModernBottomSheet, Luxury UI widgets
│   └── test/                 # Unit & widget test suites
│
├── kasyaba-backend/
│   ├── prisma/               # Database schema & migrations
│   └── src/
│       ├── config/           # Environment validation & DB pooler
│       ├── modules/          # Auth, accounts, transactions, bills, goals, planning
│       ├── jobs/             # Scheduled runway snapshots & daily worker
│       └── routes/           # REST endpoints (/api/v1/...)
└── README.md
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
