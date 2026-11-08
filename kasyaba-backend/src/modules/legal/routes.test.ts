import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../../app';

const app = createApp();

const PAGES = ['/privacy', '/terms', '/account-deletion'] as const;

/**
 * Copy assertions for the online-first policy rewrite. These guard the shipped
 * HTML against silent drift from the behavior documented in
 * docs/compliance/policy-code-matrix.md.
 */
describe('Public legal pages', () => {
  it.each(PAGES)('serves %s as HTML', async (path) => {
    const res = await request(app).get(path);

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('text/html');
    expect(res.text).toContain('KASYABA');
  });

  it('states every required online-first and security claim on /privacy', async () => {
    const res = await request(app).get('/privacy');
    const html = res.text.toLowerCase();
    const requiredClaims = [
      'online-first',
      'Argon2id',
      'SHA-256',
      '72 hours',
      'plaintext local database',
      '00:10 Asia/Manila',
      'HTTPS/TLS',
      'used only for rate limiting',
      'Jelo Abihay',
      'not a bank, financial institution, or lender',
      'are automatically overwritten within 30 days',
      'https://api.kasyaba.site/account-deletion',
      'full account snapshot',
      'CSV contains transactions only',
    ];

    for (const claim of requiredClaims) {
      expect(html, `missing required claim: ${claim}`).toContain(
        claim.toLowerCase(),
      );
    }
  });

  it('contains no retired or unverified claims on any legal page', async () => {
    const bannedClaims = [
      'TLS 1.3',
      'AES-256',
      'Google Sign-In',
      'local-first',
      'Local-First Edge Engine',
      'Every calculation runs on your device',
      '100% on-device',
      'entire database snapshot in standard JSON or CSV',
    ];

    for (const path of PAGES) {
      const res = await request(app).get(path);
      const html = res.text.toLowerCase();

      for (const claim of bannedClaims) {
        expect(html, `${path} must not contain "${claim}"`).not.toContain(
          claim.toLowerCase(),
        );
      }
    }
  });

  it('links all three legal pages from every footer', async () => {
    const footerLinks = [
      'href="https://api.kasyaba.site/terms"',
      'href="https://api.kasyaba.site/privacy"',
      'href="https://api.kasyaba.site/account-deletion"',
    ];

    for (const path of PAGES) {
      const res = await request(app).get(path);

      for (const link of footerLinks) {
        expect(res.text, `${path} is missing footer link ${link}`).toContain(
          link,
        );
      }
    }
  });
});
