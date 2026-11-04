import { Resend } from 'resend';
import { env } from '../config/env';
import { logger } from './logger';

let resendClient: Resend | null = null;

function getResendClient(): Resend | null {
  if (!env.RESEND_API_KEY) {
    return null;
  }
  if (!resendClient) {
    resendClient = new Resend(env.RESEND_API_KEY);
  }
  return resendClient;
}

/**
 * Sends a 6-digit OTP verification code for password reset.
 * Returns true if sent successfully, or false if skipped/failed.
 * Never throws an error so authentication endpoints remain resilient.
 */
export async function sendOtpEmail(to: string, otp: string): Promise<boolean> {
  const resend = getResendClient();
  if (!resend) {
    logger.info(
      { to, otpLength: otp.length },
      '[email] RESEND_API_KEY is not set. Skipping email dispatch.',
    );
    return false;
  }

  const subject = `Your ${env.APP_NAME} Verification Code: ${otp}`;
  const textBody = `Hello,

Your verification code to reset your ${env.APP_NAME} password is: ${otp}

This code will expire in 10 minutes. If you did not request this, you can safely ignore this email.

— The ${env.APP_NAME} Team`;

  const htmlBody = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>${subject}</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
      background-color: #0b111e;
      color: #e2e8f0;
      margin: 0;
      padding: 40px 20px;
    }
    .container {
      max-width: 500px;
      margin: 0 auto;
      background: #111a2e;
      border: 1px solid #1e293b;
      border-radius: 20px;
      padding: 36px 32px;
      text-align: center;
    }
    .brand {
      font-size: 24px;
      font-weight: 800;
      letter-spacing: -0.5px;
      color: #8be4d2;
      margin-bottom: 24px;
    }
    .title {
      font-size: 20px;
      font-weight: 700;
      color: #f8fafc;
      margin-bottom: 12px;
    }
    .desc {
      font-size: 14px;
      color: #94a3b8;
      line-height: 1.6;
      margin-bottom: 28px;
    }
    .otp-card {
      background: #0b111e;
      border: 1px solid #1e293b;
      border-radius: 14px;
      padding: 20px;
      margin-bottom: 28px;
      display: inline-block;
    }
    .otp-code {
      font-size: 36px;
      font-weight: 800;
      letter-spacing: 8px;
      color: #8be4d2;
      font-family: monospace, Courier;
    }
    .expiry {
      font-size: 13px;
      color: #64748b;
      margin-bottom: 24px;
    }
    .footer {
      font-size: 12px;
      color: #475569;
      border-top: 1px solid #1e293b;
      padding-top: 20px;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="brand">${env.APP_NAME}</div>
    <div class="title">Reset Your Password</div>
    <div class="desc">
      We received a request to reset your password. Use the verification code below in the app to continue:
    </div>
    <div class="otp-card">
      <div class="otp-code">${otp}</div>
    </div>
    <div class="expiry">This code will expire in 10 minutes.</div>
    <div class="footer">
      If you did not request this password reset, please ignore this email or contact support.
    </div>
  </div>
</body>
</html>
`;

  try {
    const { error } = await resend.emails.send({
      from: env.RESEND_FROM_EMAIL,
      to,
      subject,
      text: textBody,
      html: htmlBody,
    });

    if (error) {
      logger.error({ err: error, to }, '[email] Failed to send OTP email via Resend');
      return false;
    }

    logger.info({ to }, '[email] OTP email sent successfully via Resend');
    return true;
  } catch (err) {
    logger.error({ err, to }, '[email] Unexpected error sending email via Resend');
    return false;
  }
}
