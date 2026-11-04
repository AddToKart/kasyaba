import type { Request, Response, Router } from 'express';
import { env } from '../../config/env';

/**
 * Public legal pages. Google Play requires a publicly reachable privacy policy
 * URL and an account-deletion URL for apps that support account creation.
 * These routes are intentionally outside `/api/v1` and require no auth.
 */
export function registerRoutes(router: Router) {
  router.get('/privacy', (_req: Request, res: Response) => {
    res.type('html').send(
      renderPage(
        'Privacy Policy',
        `
        <h1>KASYABA Privacy Policy</h1>
        <p class="updated">Last updated: November 5, 2026</p>
        <p>KASYABA is a personal finance tracker built around a hybrid, local-first architecture. This policy explains how your data is handled, stored, and protected in compliance with the <strong>Philippine Data Privacy Act of 2012 (Republic Act No. 10173)</strong> and global privacy standards. We do not sell your personal or financial data.</p>

        <h2>Core Privacy Commitments</h2>
        <ul>
          <li><strong>Zero AI &amp; No Trackers:</strong> KASYABA never shares, sells, or transmits your financial records, salary, or account transactions to third-party AI models (e.g. OpenAI, Gemini) or ad networks.</li>
          <li><strong>Local-First Edge Engine:</strong> All daily safe-to-spend math, payday countdowns, and statutory tax deductions compute deterministically on your device.</li>
          <li><strong>Secure Sync &amp; Backup:</strong> When connected, your records synchronize to your private KASYABA backend account using encrypted channels (TLS 1.3 in transit and AES-256 / Argon2id at rest).</li>
          <li><strong>Data Privacy Act (RA 10173) Compliance:</strong> We uphold your rights as a data subject &mdash; including the right to be informed, access, rectify, erase, and port your data.</li>
        </ul>

        <h2>1. Data We Collect</h2>
        <ul>
          <li><strong>Account Information:</strong> Email address, display name, and password hashes (Argon2id). For Google Sign-In, we store your verified Google account ID and avatar URL.</li>
          <li><strong>Financial Records You Enter:</strong> Wallets/accounts, income sources, expenses, categories, monthly budgets, savings goals, bills, and notes.</li>
          <li><strong>Locally-Derived Analytics:</strong> Financial health scores, safe-to-spend buffer metrics, and cash flow snapshots calculated for your dashboard.</li>
          <li><strong>Technical Session Data:</strong> Authenticated session records (cryptographically hashed SHA-256 refresh tokens, timestamps, IP for rate-limiting). We do not use third-party analytics SDKs, advertising cookies, or behavioral trackers.</li>
        </ul>

        <h2>2. How We Use Your Data</h2>
        <ul>
          <li>To provide core personal budgeting and multi-wallet balance tracking.</li>
          <li>To synchronize your ledger across your authenticated devices.</li>
          <li>To compute deterministic financial health scores and safe-to-spend recommendations.</li>
          <li>To authenticate your sessions, rotate tokens securely, and prevent credential abuse.</li>
        </ul>

        <h2>3. Storage, Encryption &amp; Security</h2>
        <p>All client-server communications require TLS 1.3 (HTTPS). Cloud data is stored in an encrypted PostgreSQL database. Passwords are salted and hashed using Argon2id. Refresh tokens are stored strictly as SHA-256 hashes &mdash; cleartext tokens are never persisted.</p>

        <h2>4. Data Sharing &amp; Third Parties</h2>
        <p>We <strong>never sell, rent, monetize, or broker</strong> your personal or financial information. Data is processed exclusively by cloud infrastructure providers strictly necessary to operate the service (database and hosting) under confidentiality agreements. We disclose data only if required by a valid legal subpoena or court order.</p>

        <h2>5. Data Retention, Portability &amp; Deletion</h2>
        <p>Your records are kept only as long as your account remains active. You maintain 100% data ownership:</p>
        <ul>
          <li><strong>Export:</strong> Download your entire database snapshot at any time in standard JSON or CSV format via <em>Settings &rarr; Export &amp; Backup</em>.</li>
          <li><strong>Deletion:</strong> Irreversibly delete your account and all associated ledger records directly within the app via <em>Settings &rarr; Delete Account and Data</em>, or online via <a href="/account-deletion">/account-deletion</a>.</li>
        </ul>

        <h2>6. Children&rsquo;s Privacy</h2>
        <p>KASYABA is not directed to individuals under 13 years of age, and we do not knowingly collect personal data from minors.</p>

        <h2>7. Contact &amp; Data Protection</h2>
        <p>For inquiries regarding data privacy or to exercise your rights under RA 10173, contact our support team at: <a href="mailto:${escapeHtml(env.SUPPORT_EMAIL)}">${escapeHtml(env.SUPPORT_EMAIL)}</a></p>
        `,
      ),
    );
  });

  router.get('/terms', (_req: Request, res: Response) => {
    res.type('html').send(
      renderPage(
        'Terms of Service',
        `
        <h1>KASYABA Terms of Service</h1>
        <p class="updated">Last updated: November 5, 2026</p>
        <p>By creating an account or using KASYABA, you agree to these Terms of Service. Please review them before continuing.</p>

        <h2>1. Purpose &amp; Scope</h2>
        <p>KASYABA is an everyday personal finance management application that delivers deterministic calculations &mdash; including daily safe-to-spend limits, cash buffer forecasting, payday countdowns, and installment tracking &mdash; alongside private ledger synchronization.</p>

        <h2>2. No Financial, Investment, or Legal Advice</h2>
        <p>KASYABA is an automated budgeting calculation and self-tracking tool. It is <strong>not</strong> a bank, credit institution, registered investment advisor, broker-dealer, or certified tax consultant. All numbers and projections are based strictly on data provided by you and are for educational and budgeting planning purposes only.</p>

        <h2>3. 100% Data Ownership</h2>
        <p>You retain full, unrestricted ownership of all financial records, transactions, budgets, and savings goals you enter into KASYABA. You may export your complete financial records (JSON/CSV) or permanently purge your account at any time without fees or lock-in.</p>

        <h2>4. Hybrid Architecture &amp; Privacy</h2>
        <p>All daily financial math runs locally on your device. Your financial ledger syncs to your private authenticated account over encrypted channels for cross-device access and backup. We do not sell your data, use third-party behavioral trackers, or feed your numbers into third-party AI models.</p>

        <h2>5. Account Responsibility &amp; Security</h2>
        <p>You are responsible for maintaining the confidentiality of your login credentials. If you detect unauthorized activity on your account, please change your password immediately and notify support.</p>

        <h2>6. Termination &amp; Deletion</h2>
        <p>You may terminate your account at any time. When you trigger account deletion via <em>Settings &rarr; Delete Account and Data</em> or via our online <a href="/account-deletion">Account Deletion Portal</a>, all financial data, session tokens, and profile records are permanently and irreversibly purged from our databases.</p>

        <h2>7. Contact Support</h2>
        <p>For questions or assistance regarding these terms, please contact: <a href="mailto:${escapeHtml(env.SUPPORT_EMAIL)}">${escapeHtml(env.SUPPORT_EMAIL)}</a></p>
        `,
      ),
    );
  });

  router.get('/account-deletion', (_req: Request, res: Response) => {
    res.type('html').send(
      renderPage(
        'Delete Your KASYABA Account',
        `
        <h1>Delete Your KASYABA Account</h1>
        <p class="updated">Self-service data removal portal</p>
        <p>You can permanently delete your KASYABA account and all associated financial records at any time. Deletion is irreversible.</p>

        <h2>Option 1 &mdash; In the App (Instant)</h2>
        <ol>
          <li>Open KASYABA on your device and sign in.</li>
          <li>Go to <strong>Settings &rarr; Delete Account and Data</strong>.</li>
          <li>Review the notice and tap <strong>Delete Permanently</strong>.</li>
        </ol>

        <h2>Option 2 &mdash; Online Request</h2>
        <p>If you no longer have access to the app, you can submit an email deletion request to:
        <a href="mailto:${escapeHtml(env.SUPPORT_EMAIL)}?subject=Account%20Deletion%20Request">${escapeHtml(env.SUPPORT_EMAIL)}</a>
        from the email address registered with your KASYABA account with the subject line <em>&ldquo;Account Deletion Request&rdquo;</em>. We will verify identity and purge all records within 30 days.</p>

        <h2>What Gets Permanently Deleted</h2>
        <ul>
          <li><strong>Profile:</strong> Email, full name, avatar, and account credentials.</li>
          <li><strong>Financial Ledger:</strong> All accounts, wallets, income streams, expenses, transactions, categories, budgets, and savings goals.</li>
          <li><strong>Forecasts &amp; Snapshots:</strong> All computed health scores, safe-to-spend benchmarks, and alert records.</li>
          <li><strong>Sessions:</strong> All active authentication tokens and device sessions are instantly invalidated.</li>
        </ul>
        <p>No copies or backups of your financial records are retained following account purge.</p>
        `,
      ),
    );
  });
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function renderPage(title: string, body: string): string {
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>${escapeHtml(title)} — KASYABA</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0; background: #0b0f14; color: #e6e9ee;
    font: 16px/1.65 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  }
  main { max-width: 760px; margin: 0 auto; padding: 48px 24px 80px; }
  h1 { font-size: 30px; line-height: 1.25; margin: 0 0 8px; letter-spacing: -0.4px; color: #f2f5f9; }
  h2 { font-size: 19px; margin: 32px 0 8px; color: #7dd3a8; }
  p, li { color: #c7cdd6; }
  a { color: #7dd3a8; text-decoration: underline; text-underline-offset: 3px; }
  a:hover { color: #a3e7c3; }
  .updated { color: #8b93a1; font-size: 14px; margin-bottom: 24px; }
  ul, ol { padding-left: 22px; }
  strong { color: #eef1f5; }
  nav.footer-links {
    margin-top: 56px;
    padding-top: 24px;
    border-top: 1px solid #1a2533;
    display: flex;
    gap: 18px;
    font-size: 14px;
  }
  nav.footer-links a { color: #8b93a1; text-decoration: none; }
  nav.footer-links a:hover { color: #e6e9ee; }
</style>
</head>
<body>
<main>
${body}
<nav class="footer-links">
  <a href="/terms">Terms of Service</a>
  <span>&bull;</span>
  <a href="/privacy">Privacy Policy</a>
  <span>&bull;</span>
  <a href="/account-deletion">Account Deletion</a>
</nav>
</main>
</body>
</html>`;
}
