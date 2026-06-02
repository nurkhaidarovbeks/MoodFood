import nodemailer from 'nodemailer'
import { env } from '../config/env'

interface SendEmailOptions {
  to: string
  subject: string
  html: string
  text?: string
}

function createTransport(): nodemailer.Transporter | null {
  if (!env.SMTP_HOST || !env.SMTP_USER) {
    return null
  }
  return nodemailer.createTransport({
    host: env.SMTP_HOST,
    port: env.SMTP_PORT,
    secure: env.SMTP_PORT === 465,
    auth: {
      user: env.SMTP_USER,
      pass: env.SMTP_PASS,
    },
  })
}

const transport = createTransport()

export async function sendEmail(options: SendEmailOptions): Promise<void> {
  if (!transport) {
    // Development stub: log to console instead of sending real email
    console.log('[EMAIL STUB] ─────────────────────────────')
    console.log(`  To:      ${options.to}`)
    console.log(`  Subject: ${options.subject}`)
    console.log(`  Body:    ${options.text ?? options.html}`)
    console.log('[EMAIL STUB] ─────────────────────────────')
    return
  }

  await transport.sendMail({
    from: env.SMTP_FROM,
    to: options.to,
    subject: options.subject,
    html: options.html,
    text: options.text,
  })
}

export async function sendOtpEmail(email: string, otp: string): Promise<void> {
  await sendEmail({
    to: email,
    subject: 'Your MoodFood login code',
    text: `Your one-time login code is: ${otp}\n\nThis code expires in 5 minutes. If you didn't request this, ignore this email.`,
    html: `
      <h2>Your MoodFood login code</h2>
      <p>Use the code below to log in. It expires in <strong>5 minutes</strong>.</p>
      <p style="font-size:32px;font-weight:bold;letter-spacing:8px;text-align:center;padding:16px;background:#f4f4f5;border-radius:8px;">${otp}</p>
      <p>If you didn't request this code, you can safely ignore this email.</p>
    `,
  })
}

export async function sendVerificationEmail(email: string, rawToken: string): Promise<void> {
  const verifyUrl = `${env.APP_URL}/api/v1/auth/verify-email?token=${rawToken}`
  await sendEmail({
    to: email,
    subject: 'Verify your MoodFood account',
    text: `Verify your email: ${verifyUrl}\n\nThis link expires in 24 hours. If you didn't sign up for MoodFood, ignore this email.`,
    html: `
      <h2>Welcome to MoodFood!</h2>
      <p>Please verify your email address by clicking the link below:</p>
      <p><a href="${verifyUrl}" style="background:#4f46e5;color:#fff;padding:12px 24px;border-radius:6px;text-decoration:none;">Verify Email</a></p>
      <p>Or copy this link: <code>${verifyUrl}</code></p>
      <p>This link expires in 24 hours.</p>
      <p>If you didn't create a MoodFood account, you can safely ignore this email.</p>
    `,
  })
}
