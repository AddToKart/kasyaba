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
        <p class="updated">Last updated: October 5, 2026</p>
        <p>KASYABA is a personal finance tracker. This policy explains what we collect,
        why we collect it, and the choices you have. We do not sell your personal or
        financial data.</p>

        <h2>1. Data we collect</h2>
        <ul>
          <li><strong>Account data:</strong> email address, display name, and (for Google
          Sign-In) your Google account identifier and avatar URL.</li>
          <li><strong>Financial data you enter:</strong> accounts, income, expenses,
          categories, budgets, savings goals, bills, and notes.</li>
          <li><strong>Derived data:</strong> forecasts, snapshots, and alerts computed from
          the data you enter.</li>
          <li><strong>Technical data:</strong> authentication session records (hashed refresh
          tokens, timestamps). We do not use advertising or third-party analytics trackers.</li>
        </ul>

        <h2>2. How we use it</h2>
        <ul>
          <li>To provide the app: storing your records and synchronizing them across sessions.</li>
          <li>To compute deterministic forecasts, alerts, and your financial health score.</li>
          <li>To secure your account: authentication, session rotation, abuse prevention.</li>
        </ul>

        <h2>3. Storage and security</h2>
        <p>Data is transmitted over HTTPS and stored in a managed PostgreSQL database.
        Passwords are hashed with Argon2id. Refresh tokens are stored only as SHA-256
        hashes. Access is scoped to your authenticated account.</p>

        <h2>4. Sharing</h2>
        <p>We do not sell or rent personal data. Data is processed only by the
        infrastructure providers required to run the service (database and hosting),
        under their standard data-processing terms. We may disclose data if required
        by law.</p>

        <h2>5. Retention and deletion</h2>
        <p>Your data is retained while your account is active. You can permanently delete
        your account and all associated records at any time from
        <em>Settings &rarr; Delete Account and Data</em>, or by following the instructions at
        <a href="/account-deletion">/account-deletion</a>.</p>

        <h2>6. Children</h2>
        <p>KASYABA is not directed to children under 13 and we do not knowingly collect
        data from them.</p>

        <h2>7. Contact</h2>
        <p>Privacy questions: <a href="mailto:${escapeHtml(env.SUPPORT_EMAIL)}">${escapeHtml(env.SUPPORT_EMAIL)}</a></p>
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
        <p>You can permanently delete your KASYABA account and all associated data at
        any time. Deletion is irreversible.</p>

        <h2>Option 1 — In the app (recommended)</h2>
        <ol>
          <li>Open KASYABA and sign in.</li>
          <li>Go to <strong>Settings &rarr; Delete Account and Data</strong>.</li>
          <li>Confirm <strong>Delete Permanently</strong>.</li>
        </ol>

        <h2>Option 2 — By email</h2>
        <p>If you cannot access the app, email
        <a href="mailto:${escapeHtml(env.SUPPORT_EMAIL)}?subject=Account%20Deletion%20Request">${escapeHtml(env.SUPPORT_EMAIL)}</a>
        from the address registered to your account with the subject
        &ldquo;Account Deletion Request&rdquo;. We will verify ownership and complete the
        deletion within 30 days.</p>

        <h2>What gets deleted</h2>
        <ul>
          <li>Your profile: email, display name, Google identifier, and preferences.</li>
          <li>All financial records: accounts, income, expenses, categories, budgets,
          savings goals and contributions, bills, snapshots, and alerts.</li>
          <li>All active login sessions, which are revoked immediately.</li>
        </ul>
        <p>No copy of your records is retained after deletion, except where a short
        retention is required by law or for fraud prevention.</p>
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
  h1 { font-size: 30px; line-height: 1.25; margin: 0 0 8px; letter-spacing: -0.4px; }
  h2 { font-size: 19px; margin: 32px 0 8px; color: #f3d9a4; }
  p, li { color: #c7cdd6; }
  a { color: #7dd3a8; }
  .updated { color: #8b93a1; font-size: 14px; }
  ul, ol { padding-left: 22px; }
  strong { color: #eef1f5; }
</style>
</head>
<body><main>${body}
<p style="margin-top:48px"><a href="/privacy">Privacy Policy</a></p>
</main></body>
</html>`;
}
