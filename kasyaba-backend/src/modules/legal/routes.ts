import type { Request, Response, Router } from 'express';
import { env } from '../../config/env';

/**
 * Public legal pages. Store policy requires a publicly reachable privacy
 * policy URL and an account-deletion URL for apps that support account creation.
 * These routes are intentionally outside `/api/v1` and require no auth.
 *
 * Copy rule: these pages describe the online-first architecture contract in
 * plan-offline-compliance.md §1. The server is the source of truth; device
 * math, caches, and the offline queue are a fast local layer. Keep shipped
 * copy aligned with the locked compliance decisions.
 */
export function registerRoutes(router: Router) {
  router.get('/privacy', (_req: Request, res: Response) => {
    res.type('html').send(
      renderPage(
        'Privacy Policy',
        `
        <h1>KASYABA Privacy Policy</h1>
        <p class="updated">Last updated: November 6, 2026 &middot; Policy version 2.0</p>
        <p>KASYABA is developed and operated by <strong>Jelo Abihay</strong> (the &ldquo;KASYABA&rdquo; developer account published on Google Play). KASYABA is an online-first personal finance tracker. Your ledger is stored on our server, which is the source of truth for your account. The app adds on-device math for instant feedback and a local cache for continuity when connectivity is limited. This policy explains what we collect, where it is processed and stored, how long we keep it, and your rights under the <strong>Philippine Data Privacy Act of 2012 (Republic Act No. 10173)</strong>. KASYABA is strictly a personal budgeting, financial tracking, and forecasting utility: it is <strong>not a bank, financial institution, or lender</strong>, and it does not facilitate real-world money transfers, credit issuance, or loan disbursements. We do not sell your personal or financial data.</p>

        <h2>Architecture Summary</h2>
        <ul>
          <li><strong>Server (PostgreSQL) &mdash; source of truth:</strong> accounts and wallets; posted and planned transactions; bills, bill templates, and generated bill instances; budgets; goals and contributions; financial snapshots; and alerts.</li>
          <li><strong>Server-run:</strong> the 30-day planning horizon and pressure levels; financial health score and grade; month-to-date and predicted month-end figures; the daily snapshot job at 00:10 Asia/Manila; and hourly bill-instance generation up to two months ahead, including overdue status updates.</li>
          <li><strong>Device-run (deterministic, instant):</strong> daily safe-to-spend (with your excluded wallets), payday countdown for all supported schedules, PH statutory deductions (SSS, PhilHealth, Pag-IBIG, and income tax), the interactive affordability simulator math (cash versus installment, interest and amortization, cash preserved, and work-hours equivalent), allocation proportions, and goal progress. The final affordability verdict, cash-after-bills figure, and earliest safe buy date are computed by the server at <code>/forecasting/purchase-check</code>.</li>
          <li><strong>Device storage:</strong> authentication tokens and app preferences (theme, notification preferences, and safe-to-spend excluded accounts) are kept in encrypted secure storage. An offline snapshot cache and an offline queue are kept in a plaintext local database on the device.</li>
        </ul>
        <p>In short, KASYABA is <strong>online-first, with on-device math for instant feedback</strong>. The server remains the authoritative record; device calculations are a fast local layer over the last data you loaded.</p>

        <h2>Core Privacy Commitments</h2>
        <ul>
          <li><strong>Zero AI &amp; No Trackers:</strong> KASYABA never shares, sells, or transmits your financial records, salary, or account transactions to third-party AI models (such as OpenAI or Gemini) or ad networks. We do not use third-party analytics SDKs, advertising cookies, or behavioral trackers.</li>
          <li><strong>Server-backed records:</strong> your accounts, wallets, transactions, bills, budgets, goals, snapshots, and alerts are stored in our PostgreSQL database, not only on your phone.</li>
          <li><strong>Secure sync:</strong> your data is encrypted in transit using HTTPS/TLS when it moves between your device and our server.</li>
          <li><strong>Data Privacy Act (RA 10173) Compliance:</strong> we uphold your rights as a data subject &mdash; including the right to be informed, access, rectify, erase, and port your data.</li>
        </ul>

        <h2>1. Data We Collect</h2>
        <ul>
          <li><strong>Account Information:</strong> email address, display name, and a salted password hash produced with Argon2id. We do not store your password in cleartext.</li>
          <li><strong>Financial Records You Enter:</strong> accounts and wallets, salary and other income sources, expenses, categories, transfers, monthly budgets, savings goals and contributions, bills (including bill templates and generated bill instances), and notes.</li>
          <li><strong>Server-Computed Analytics:</strong> financial health scores and grades, month-to-date and predicted month-end figures, 30-day planning views, daily financial snapshots, and alert records calculated from your ledger.</li>
          <li><strong>Technical Session Data:</strong> session records containing SHA-256 hashes of refresh tokens, timestamps, and IP addresses used only for rate limiting. We do not store cleartext refresh tokens. We do not use third-party analytics SDKs, advertising cookies, or behavioral trackers.</li>
          <li><strong>Device-Local Data:</strong> encrypted authentication tokens and app preferences, plus the plaintext snapshot cache and offline queue described in section 4.</li>
        </ul>

        <h2>2. How We Use Your Data</h2>
        <ul>
          <li>To provide core personal budgeting, multi-wallet balance tracking, and your transaction history.</li>
          <li>To synchronize your ledger across your authenticated devices.</li>
          <li>To compute server-side planning (30-day horizon and pressure levels), financial health scores and grades, month-to-date and predicted month-end figures, daily snapshots, and alerts.</li>
          <li>To generate bill instances up to two months ahead and update overdue bill statuses on a schedule.</li>
          <li>To authenticate your sessions, rotate tokens securely, rate-limit requests, and prevent credential abuse.</li>
          <li>To respond to support requests and data-subject requests under RA 10173.</li>
        </ul>

        <h2>3. Online-First Processing &mdash; What Runs Where</h2>
        <p>KASYABA is <strong>online-first, with on-device math for instant feedback</strong>. Some calculations run on our server and require an internet connection; others run on your device immediately from the last data you loaded.</p>
        <ul>
          <li><strong>Server-run (requires a connection):</strong> the 30-day planning horizon and pressure levels; financial health score and grade; month-to-date and predicted month-end figures; daily snapshots; hourly bill-instance generation and overdue flips; and the final affordability verdict, cash-after-bills figure, and earliest safe buy date at <code>/forecasting/purchase-check</code>.</li>
          <li><strong>Device-run (deterministic, instant):</strong> daily safe-to-spend with your excluded wallets, payday countdown for all supported schedules, PH statutory deductions, the interactive affordability simulator math (cash versus installment, interest and amortization, cash preserved, and work-hours equivalent), allocation proportions, and goal progress.</li>
        </ul>
        <p>Device results are a fast local layer; server results remain the authoritative record for planning, health, and forecast decisions.</p>

        <h2>4. Device Storage &amp; Offline Behavior</h2>
        <p>We disclose the device layer plainly:</p>
        <ul>
          <li><strong>Encrypted secure storage:</strong> authentication tokens and app preferences (theme, notification preferences, and safe-to-spend excluded accounts).</li>
          <li><strong>Plaintext local database (Drift/SQLite):</strong> an offline snapshot cache of your dashboard, wallets, recent transactions, bills, goals, budgets, alerts, and categories. This database is not encrypted at the database level. It is protected by your device&rsquo;s operating-system sandbox and lock screen; anyone with access to an unlocked or rooted device may be able to read it.</li>
          <li><strong>Offline queue:</strong> expense, income, transfer, and goal-deposit entries you create while offline are stored in the same plaintext local database and replayed to the server when connectivity returns. Each entry is retried up to five times; entries that still fail are shown in the app with the failure reason so you can review them.</li>
        </ul>
        <p>Signing out clears your authentication tokens and read caches from the device. The offline queue is tagged to your unique account ID and retained across sign-out to avoid losing unsynced entries; it is only re-attached if the same account signs back in, and it is never shown to a different account. App preferences remain until you clear the app&rsquo;s storage or uninstall the app. Deleting your account through the app wipes tokens, read caches, and the queue. If deletion is completed through the web portal while the app is offline, the device clears its read caches the next time the app signs out or its session is revoked; because the offline queue is intentionally retained across sign-out, unsynced entries may remain on that device &mdash; uninstall the app or clear its storage to remove them.</p>

        <h2>5. Storage, Encryption &amp; Security</h2>
        <p>Data is encrypted in transit using HTTPS/TLS. Passwords are salted and hashed with Argon2id; we never store cleartext passwords. Refresh tokens are stored only as SHA-256 hashes; cleartext refresh tokens are never persisted on the server. IP addresses are used only for rate limiting.</p>
        <p>Your records are stored in a PostgreSQL database on our server infrastructure. Access is limited to the service and to personnel who need it to operate, support, or secure the service. Device caches are plaintext as described in section 4.</p>

        <h2>6. Data Sharing &amp; Third Parties</h2>
        <p>We <strong>never sell, rent, monetize, or broker</strong> your personal or financial information. Data is processed only by infrastructure providers strictly necessary to operate the service (hosting, database, and email delivery for verification codes) under confidentiality obligations. We disclose data only when required by a valid legal subpoena or court order, or when necessary to protect the service from abuse.</p>
        <p>We do not share your data with advertising networks, data brokers, or third-party AI providers.</p>

        <h2>7. Data Retention, Portability &amp; Deletion</h2>
        <p>We retain your records while your account is active. Session records have a fixed expiry; expired sessions are pruned. When you delete your account, we delete your profile and financial records from the live production database and revoke all sessions.</p>
        <ul>
          <li><strong>Export:</strong> download a full account snapshot in JSON, or export your transaction history in CSV, via <em>Settings &rarr; Export &amp; Backup</em>. JSON contains your account snapshot; CSV contains transactions only and does not include budgets, goals, bills, or account settings.</li>
          <li><strong>Deletion:</strong> irreversibly delete your account and associated ledger records directly in the app via <em>Settings &rarr; Delete Account and Data</em>, or online via <a href="https://api.kasyaba.site/account-deletion">https://api.kasyaba.site/account-deletion</a>.</li>
        </ul>
        <p>We do not keep a separate archive of your ledger after deletion. Infrastructure backups, where configured, are automatically overwritten within 30 days and are never used to restore deleted accounts.</p>

        <h2>8. Breach Notification</h2>
        <p>If we discover a personal data breach that qualifies for notification under RA 10173 and its Implementing Rules and Regulations, we will notify the National Privacy Commission and affected users within 72 hours of discovery, consistent with the applicable requirements.</p>

        <h2>9. Children&rsquo;s Privacy</h2>
        <p>KASYABA is not directed to individuals under 13 years of age, and we do not knowingly collect personal data from minors.</p>

        <h2>10. Contact &amp; Data Protection</h2>
        <p>KASYABA is developed and operated by <strong>Jelo Abihay</strong>. For inquiries regarding data privacy, or to exercise your rights under RA 10173, contact our support team at: <a href="mailto:${escapeHtml(env.SUPPORT_EMAIL)}">${escapeHtml(env.SUPPORT_EMAIL)}</a></p>

        <h2>11. Policy Version &amp; Changelog</h2>
        <p><strong>Version 2.1 &mdash; November 6, 2026:</strong> added the developer identity, a not-a-bank / not-a-lender scope statement, a concrete 30-day infrastructure-backup bound, absolute legal-page URLs, and clarified that the offline queue is account-tagged and never shown to a different account.</p>
        <p><strong>Version 2.0 &mdash; November 6, 2026:</strong> rewritten for the online-first architecture. Clarified which calculations run on the server and which run on-device; disclosed the plaintext device cache and offline queue; corrected the export scope, encryption wording, retention statement, and breach-notification commitment.</p>
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
        <p class="updated">Last updated: November 6, 2026</p>
        <p>By creating an account or using KASYABA, you agree to these Terms of Service. Please review them before continuing.</p>

        <h2>1. Purpose &amp; Scope</h2>
        <p>KASYABA is an everyday personal finance management application. Your ledger is stored on our server, which is the source of truth for your account. The service combines server-side planning and forecasting with deterministic on-device math for instant feedback, plus an offline cache and queue for continuity when connectivity is limited.</p>

        <h2>2. No Financial, Investment, or Legal Advice</h2>
        <p>KASYABA is an automated budgeting calculation and self-tracking tool. It is <strong>not</strong> a bank, credit institution, registered investment advisor, broker-dealer, or certified tax consultant. All numbers and projections are based strictly on data provided by you and are for educational and budgeting planning purposes only.</p>

        <h2>3. Your Data &amp; Ownership</h2>
        <p>You retain ownership of the financial records, transactions, budgets, and savings goals you enter into KASYABA. You may export a full account snapshot in JSON, or export your transaction history in CSV (CSV contains transactions only), or permanently delete your account at any time without fees or lock-in.</p>

        <h2>4. Online-First Architecture &amp; Privacy</h2>
        <p>KASYABA is <strong>online-first, with on-device math for instant feedback</strong>. Day-to-day math runs on-device; server-side planning, health, and forecast calculations are online-only. Specifically:</p>
        <ul>
          <li><strong>On-device:</strong> daily safe-to-spend (including excluded wallets), payday countdown, PH statutory deductions, the interactive affordability simulator math (cash versus installment, interest and amortization, cash preserved, and work-hours equivalent), allocation proportions, and goal progress.</li>
          <li><strong>Server-side (requires a connection):</strong> the 30-day planning horizon and pressure levels, financial health score and grade, month-to-date and predicted month-end figures, daily snapshots, bill generation and overdue updates, and the final affordability verdict, cash-after-bills figure, and earliest safe buy date.</li>
        </ul>
        <p>Your ledger is stored on our server as the source of truth. The device keeps encrypted authentication tokens and app preferences, a plaintext snapshot cache (dashboard, wallets, recent transactions, bills, goals, budgets, alerts, and categories), and a plaintext offline queue for expense, income, transfer, and goal-deposit entries. Queued entries replay when connectivity returns; each is retried up to five times, and failed entries are surfaced in the app. Signing out clears read caches but keeps the offline queue; deleting your account wipes tokens, caches, and the queue.</p>
        <p>We do not sell your data, use third-party behavioral trackers, or feed your numbers into third-party AI models.</p>

        <h2>5. Account Responsibility &amp; Security</h2>
        <p>You are responsible for maintaining the confidentiality of your login credentials. If you detect unauthorized activity on your account, please change your password immediately and notify support.</p>

        <h2>6. Availability &amp; Offline Use</h2>
        <p>Online-only features &mdash; including the 30-day planning horizon, health score, month-to-date and predicted month-end figures, bill generation, and the final affordability verdict &mdash; require an internet connection. When you are offline, the app can show the last cached snapshot and queue certain entries for replay. Cached data may be stale, and queued entries may be delayed or fail after repeated attempts. Do not rely on KASYABA as the sole record of a payment, bill, or transfer.</p>

        <h2>7. Termination &amp; Deletion</h2>
        <p>You may terminate your account at any time. When you trigger account deletion via <em>Settings &rarr; Delete Account and Data</em> or via our online <a href="https://api.kasyaba.site/account-deletion">Account Deletion Portal</a>, your profile and financial records are deleted from the live production database and all sessions are revoked. The app also wipes tokens, caches, and the offline queue on that device. Any queued entries that have not yet synced are discarded. We do not keep a separate archive of your ledger after deletion; infrastructure backups, where configured, are automatically overwritten within 30 days and are never used to restore deleted accounts.</p>

        <h2>8. Contact Support</h2>
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
        <p class="updated">Last updated: November 6, 2026</p>
        <p>You can permanently delete your KASYABA account and all associated records at any time. Your account and financial records are stored on our server, so deletion removes them from the live production database. Deletion is irreversible.</p>

        <h2>Option 1 &mdash; In the App (Instant)</h2>
        <ol>
          <li>Open KASYABA on your device and sign in.</li>
          <li>Go to <strong>Settings &rarr; Delete Account and Data</strong>.</li>
          <li>Review the notice and tap <strong>Delete Permanently</strong>.</li>
        </ol>

        <h2>Option 2 &mdash; Online Request</h2>
        <p>If you no longer have access to the app, you can submit an email deletion request to:
        <a href="mailto:${escapeHtml(env.SUPPORT_EMAIL)}?subject=Account%20Deletion%20Request">${escapeHtml(env.SUPPORT_EMAIL)}</a>
        from the email address registered with your KASYABA account with the subject line <em>&ldquo;Account Deletion Request&rdquo;</em>. We will verify identity and process the deletion within 30 days.</p>

        <h2>Before You Delete</h2>
        <p>If you want a copy of your data, export it first via <em>Settings &rarr; Export &amp; Backup</em>. JSON gives you a full account snapshot; CSV gives you transaction history only. Sync any pending offline entries before deleting, because deletion discards the offline queue on your device.</p>

        <h2>What Gets Permanently Deleted</h2>
        <ul>
          <li><strong>Server profile:</strong> email address, display name, and account credentials (including the Argon2id password hash).</li>
          <li><strong>Server ledger:</strong> accounts and wallets, posted and planned transactions, transfers, income entries, expenses, categories, budgets, savings goals and contributions, and bills (including templates and generated instances).</li>
          <li><strong>Server analytics:</strong> financial snapshots (including health score and grade records) and alerts. Planning views are derived from your ledger and are removed with it; they are not kept as a separate record.</li>
          <li><strong>Sessions:</strong> all authentication sessions and refresh-token hashes are invalidated and removed.</li>
          <li><strong>Device data:</strong> authentication tokens, read caches, and the offline queue. In-app deletion wipes these immediately. If you delete through the web portal, the app clears read caches when its session is next revoked; unsynced queue entries are retained across sign-out by design, so uninstall the app or clear its storage to remove them.</li>
        </ul>

        <h2>Retention After Deletion</h2>
        <p>We do not keep a separate archive of your ledger after deletion. Infrastructure backups, where configured, are automatically overwritten within 30 days and are never used to restore deleted accounts. Records are otherwise retained only while your account is active, and expired sessions are pruned.</p>

        <h2>Need Help?</h2>
        <p>For questions about deletion or your rights under RA 10173, contact: <a href="mailto:${escapeHtml(env.SUPPORT_EMAIL)}">${escapeHtml(env.SUPPORT_EMAIL)}</a></p>
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
<title>${escapeHtml(title)} &mdash; KASYABA</title>
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
  code { color: #a3e7c3; font-size: 0.92em; }
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
  <a href="https://api.kasyaba.site/terms">Terms of Service</a>
  <span>&bull;</span>
  <a href="https://api.kasyaba.site/privacy">Privacy Policy</a>
  <span>&bull;</span>
  <a href="https://api.kasyaba.site/account-deletion">Account Deletion</a>
</nav>
</main>
</body>
</html>`;
}
