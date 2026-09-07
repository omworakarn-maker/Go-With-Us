/**
 * Send OTP Verification Email using Resend HTTP API
 * @param {string} to - Recipient email
 * @param {string} otp - 6-digit OTP code
 */
export const sendVerificationEmail = async (to, otp) => {
  const RESEND_API_KEY = process.env.RESEND_API_KEY;
  const gmailUser = process.env.EMAIL_USER;
  const gmailAppPassword = process.env.EMAIL_APP_PASSWORD;

  const htmlContent = `
    <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
      <h2 style="color: #ff4d4d; text-align: center;">ยืนยันอีเมลของคุณ</h2>
      <p>สวัสดีครับ,</p>
      <p>ขอบคุณที่สมัครสมาชิกกับ GoWithUs กรุณานำรหัส 6 หลักด้านล่างไปกรอกในแอปเพื่อยืนยันอีเมลของคุณ:</p>
      <div style="background-color: #f9f9f9; padding: 15px; text-align: center; border-radius: 5px; margin: 20px 0;">
        <h1 style="letter-spacing: 5px; color: #333; margin: 0;">${otp}</h1>
      </div>
      <p style="color: #666; font-size: 12px; text-align: center;">รหัสนี้มีอายุการใช้งาน 10 นาที</p>
      <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
      <p style="color: #999; font-size: 12px; text-align: center;">หากคุณไม่ได้สมัครสมาชิกแอป GoWithUs กรุณาละเว้นอีเมลฉบับนี้</p>
    </div>
  `;

  // Local/student deployment: send from the owner's Gmail without a custom domain.
  if (gmailUser && gmailAppPassword) {
    try {
      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: { user: gmailUser, pass: gmailAppPassword.replace(/\s/g, '') }
      });
      const info = await transporter.sendMail({
        from: `GoWithUs <${gmailUser}>`,
        to,
        subject: `GoWithUs OTP: ${otp}`,
        html: htmlContent
      });
      console.log(`✅ Verification email sent to ${to} via Gmail. ID: ${info.messageId}`);
      return;
    } catch (error) {
      console.error('❌ Gmail SMTP Error:', error.message);
      throw new Error('Failed to send verification email via Gmail');
    }
  }

  if (!RESEND_API_KEY) {
    console.warn('⚠️ Email is not configured. Set EMAIL_USER and EMAIL_APP_PASSWORD.');
    throw new Error('Email service is not configured');
  }

  try {
    const response = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        from: 'GoWithUs App <onboarding@resend.dev>',
        to: to,
        subject: `GoWithUs OTP: ${otp}`,
        html: htmlContent
      })
    });

    const data = await response.json();

    if (response.ok) {
      console.log(`✅ Verification email sent to ${to} via Resend. ID: ${data.id}`);
    } else {
      console.error(`❌ Resend API Error:`, data);
      throw new Error(`Resend Error: ${data.message || 'Failed to send email'}`);
    }
  } catch (error) {
    console.error(`❌ Fetch Error sending email to ${to}:`, error);
    throw new Error('Failed to send verification email via HTTP');
  }
};
import nodemailer from 'nodemailer';
