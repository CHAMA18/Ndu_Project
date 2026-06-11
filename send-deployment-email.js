#!/usr/bin/env node
/**
 * NDU Project - Standalone Deployment Email Confirmation
 *
 * This script sends a confirmation email before deploying to live domains.
 * It works independently of Firebase Cloud Functions (no deployment required).
 *
 * Usage:
 *   node send-deployment-email.js --target staging --message "Deploy v1.2" --summary "Bug fixes"
 *
 * Environment Variables:
 *   GMAIL_USER          - Gmail address for sending emails
 *   GMAIL_APP_PASSWORD  - Gmail App Password (not regular password)
 *   APPROVAL_URL_BASE   - Base URL for approval endpoint (optional)
 *
 * If email credentials are not set, the script will print a confirmation
 * request to the console and wait for manual input.
 */

const nodemailer = require('nodemailer');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

// ============================================================================
// CONFIGURATION
// ============================================================================

const OWNER_EMAIL = 'chungu424@gmail.com';
const APPROVAL_FILE = path.join(__dirname, '.deployment_approval.json');
const EXPIRY_MINUTES = 30;

// ============================================================================
// ARGUMENT PARSING
// ============================================================================

function parseArgs() {
  const args = process.argv.slice(2);
  const parsed = {
    target: 'staging',
    message: 'Manual deployment',
    summary: 'Automated deployment from CI/CD pipeline',
  };

  for (let i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--target':
        parsed.target = args[++i];
        break;
      case '--message':
        parsed.message = args[++i];
        break;
      case '--summary':
        parsed.summary = args[++i];
        break;
      case '--help':
        console.log(`
NDU Project - Deployment Email Confirmation

Usage:
  node send-deployment-email.js [options]

Options:
  --target    Deployment target: staging, admin, or both (default: staging)
  --message   Commit/deployment message
  --summary   Summary of changes
  --help      Show this help message

Environment Variables:
  GMAIL_USER          Gmail address for sending emails
  GMAIL_APP_PASSWORD  Gmail App Password
`);
        process.exit(0);
    }
  }
  return parsed;
}

// ============================================================================
// EMAIL SENDER
// ============================================================================

async function sendConfirmationEmail(requestId, target, message, summary) {
  const gmailUser = process.env.GMAIL_USER;
  const gmailAppPassword = process.env.GMAIL_APP_PASSWORD;

  if (!gmailUser || !gmailAppPassword) {
    console.log('\n' + '='.repeat(60));
    console.log('  EMAIL NOT CONFIGURED - Manual Confirmation Required');
    console.log('='.repeat(60));
    console.log(`\n  To enable email confirmation, set environment variables:`);
    console.log(`    export GMAIL_USER=your-email@gmail.com`);
    console.log(`    export GMAIL_APP_PASSWORD=your-app-password\n`);
    console.log(`  Deployment Details:`);
    console.log(`    Request ID:  ${requestId}`);
    console.log(`    Target:      ${target}`);
    console.log(`    Message:     ${message}`);
    console.log(`    Summary:     ${summary}`);
    console.log(`    Owner Email: ${OWNER_EMAIL}`);
    console.log('\n' + '='.repeat(60));
    return false;
  }

  const domains = target === 'both'
    ? ['staging.nduproject.com', 'admin.nduproject.com']
    : [`${target}.nduproject.com`];

  const domainList = domains.map(d => `<code style="background:#f1f5f9;padding:2px 8px;border-radius:4px;">${d}</code>`).join('<br>');

  const approveUrl = `https://us-central1-ndu-d3f60.cloudfunctions.net/handleDeploymentAction?action=approve&requestId=${requestId}`;
  const rejectUrl = `https://us-central1-ndu-d3f60.cloudfunctions.net/handleDeploymentAction?action=reject&requestId=${requestId}`;

  const htmlBody = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
</head>
<body style="margin:0;padding:0;background-color:#0f172a;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <div style="max-width:600px;margin:40px auto;background:#1e293b;border-radius:16px;overflow:hidden;border:1px solid #334155;">
    <!-- Header -->
    <div style="background:linear-gradient(135deg,#3b82f6,#8b5cf6);padding:32px;text-align:center;">
      <h1 style="margin:0;color:#fff;font-size:24px;font-weight:700;">NDU Project</h1>
      <p style="margin:8px 0 0;color:rgba(255,255,255,0.8);font-size:14px;">Deployment Confirmation Required</p>
    </div>

    <!-- Content -->
    <div style="padding:32px;color:#e2e8f0;">
      <p style="margin:0 0 20px;font-size:16px;">A deployment has been requested and requires your approval before proceeding.</p>

      <!-- Details Table -->
      <div style="background:#0f172a;border-radius:12px;padding:20px;margin:0 0 24px;border:1px solid #334155;">
        <table style="width:100%;border-collapse:collapse;font-size:14px;">
          <tr>
            <td style="padding:8px 12px;color:#94a3b8;font-weight:600;">Target</td>
            <td style="padding:8px 12px;color:#f1f5f9;">${target.toUpperCase()}</td>
          </tr>
          <tr>
            <td style="padding:8px 12px;color:#94a3b8;font-weight:600;">Domains</td>
            <td style="padding:8px 12px;color:#f1f5f9;">${domainList}</td>
          </tr>
          <tr>
            <td style="padding:8px 12px;color:#94a3b8;font-weight:600;">Message</td>
            <td style="padding:8px 12px;color:#f1f5f9;">${message}</td>
          </tr>
          <tr>
            <td style="padding:8px 12px;color:#94a3b8;font-weight:600;">Changes</td>
            <td style="padding:8px 12px;color:#f1f5f9;">${summary}</td>
          </tr>
          <tr>
            <td style="padding:8px 12px;color:#94a3b8;font-weight:600;">Request ID</td>
            <td style="padding:8px 12px;color:#f1f5f9;font-family:monospace;font-size:12px;">${requestId}</td>
          </tr>
          <tr>
            <td style="padding:8px 12px;color:#94a3b8;font-weight:600;">Expires</td>
            <td style="padding:8px 12px;color:#fbbf24;">${EXPIRY_MINUTES} minutes from now</td>
          </tr>
        </table>
      </div>

      <!-- Action Buttons -->
      <div style="text-align:center;margin:24px 0;">
        <a href="${approveUrl}" style="display:inline-block;padding:14px 32px;background:#22c55e;color:#fff;text-decoration:none;border-radius:8px;font-weight:600;font-size:16px;margin:0 8px;">Approve Deployment</a>
        <a href="${rejectUrl}" style="display:inline-block;padding:14px 32px;background:#ef4444;color:#fff;text-decoration:none;border-radius:8px;font-weight:600;font-size:16px;margin:0 8px;">Reject</a>
      </div>

      <p style="margin:20px 0 0;font-size:12px;color:#64748b;text-align:center;">
        This request will expire in ${EXPIRY_MINUTES} minutes if no action is taken.<br>
        Request ID: ${requestId}
      </p>
    </div>

    <!-- Footer -->
    <div style="padding:20px;text-align:center;border-top:1px solid #334155;">
      <p style="margin:0;font-size:12px;color:#475569;">
        NDU Project Deployment System<br>
        This is an automated notification.
      </p>
    </div>
  </div>
</body>
</html>`;

  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: gmailUser,
      pass: gmailAppPassword,
    },
  });

  try {
    const info = await transporter.sendMail({
      from: `"NDU Deploy Guard" <${gmailUser}>`,
      to: OWNER_EMAIL,
      subject: `[Action Required] Deployment Approval - ${target.toUpperCase()} - ${new Date().toLocaleString()}`,
      html: htmlBody,
    });
    console.log(`Confirmation email sent to ${OWNER_EMAIL}`);
    console.log(`Message ID: ${info.messageId}`);
    return true;
  } catch (error) {
    console.error('Failed to send email:', error.message);
    return false;
  }
}

// ============================================================================
// APPROVAL TRACKING (File-based for standalone mode)
// ============================================================================

function createApprovalRequest(requestId, target, message, summary) {
  const request = {
    requestId,
    target,
    message,
    summary,
    status: 'pending',
    createdAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + EXPIRY_MINUTES * 60 * 1000).toISOString(),
  };

  fs.writeFileSync(APPROVAL_FILE, JSON.stringify(request, null, 2));
  return request;
}

function checkApprovalStatus(requestId) {
  if (!fs.existsSync(APPROVAL_FILE)) {
    return { status: 'not_found' };
  }

  const request = JSON.parse(fs.readFileSync(APPROVAL_FILE, 'utf8'));

  if (request.requestId !== requestId) {
    return { status: 'not_found' };
  }

  // Check expiry
  if (new Date() > new Date(request.expiresAt)) {
    return { status: 'expired' };
  }

  return request;
}

function approveRequest(requestId) {
  if (!fs.existsSync(APPROVAL_FILE)) return false;
  const request = JSON.parse(fs.readFileSync(APPROVAL_FILE, 'utf8'));
  if (request.requestId !== requestId) return false;

  request.status = 'approved';
  request.approvedAt = new Date().toISOString();
  fs.writeFileSync(APPROVAL_FILE, JSON.stringify(request, null, 2));
  return true;
}

function rejectRequest(requestId) {
  if (!fs.existsSync(APPROVAL_FILE)) return false;
  const request = JSON.parse(fs.readFileSync(APPROVAL_FILE, 'utf8'));
  if (request.requestId !== requestId) return false;

  request.status = 'rejected';
  request.rejectedAt = new Date().toISOString();
  fs.writeFileSync(APPROVAL_FILE, JSON.stringify(request, null, 2));
  return true;
}

// ============================================================================
// MAIN
// ============================================================================

async function main() {
  const args = parseArgs();
  const requestId = crypto.randomUUID();

  console.log('\n' + '='.repeat(50));
  console.log('  NDU Project Deployment Guard');
  console.log('='.repeat(50));
  console.log(`\n  Target:   ${args.target}`);
  console.log(`  Message:  ${args.message}`);
  console.log(`  Summary:  ${args.summary}`);
  console.log(`  Request:  ${requestId}`);
  console.log('');

  // Create the approval request file
  createApprovalRequest(requestId, args.target, args.message, args.summary);

  // Try to send the confirmation email
  const emailSent = await sendConfirmationEmail(
    requestId,
    args.target,
    args.message,
    args.summary
  );

  if (!emailSent) {
    // Manual confirmation mode - wait for user input
    console.log('\n  ⏳ Waiting for your approval...');
    console.log(`  A confirmation email could NOT be sent (no Gmail credentials).`);
    console.log(`  Please respond in the chat to approve or reject this deployment.\n`);

    // In standalone mode, output a JSON status for the calling script
    const result = {
      requestId,
      emailSent: false,
      status: 'pending_manual_approval',
      target: args.target,
      message: args.message,
      summary: args.summary,
      approvalFile: APPROVAL_FILE,
    };

    console.log('RESULT:' + JSON.stringify(result));
    return;
  }

  // Email was sent - output result for the calling script
  const result = {
    requestId,
    emailSent: true,
    status: 'pending_email_approval',
    target: args.target,
    message: args.message,
    summary: args.summary,
    approvalFile: APPROVAL_FILE,
  };

  console.log('RESULT:' + JSON.stringify(result));
}

main().catch((err) => {
  console.error('Error:', err.message);
  process.exit(1);
});
