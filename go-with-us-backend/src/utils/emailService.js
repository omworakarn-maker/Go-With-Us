import nodemailer from 'nodemailer';

// Create a transporter using Gmail SMTP
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS
  }
});

/**
 * Send OTP Verification Email
 * @param {string} to - Recipient email
 * @param {string} otp - 6-digit OTP code
 */
export const sendVerificationEmail = async (to, otp) => {
  // If SMTP is not configured, just log to console for development testing
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
    console.log(`\n======================================================`);
    console.log(`📧 [MOCK EMAIL] To: ${to}`);
    console.log(`🔑 [MOCK OTP] Your verification code is: ${otp}`);
    console.log(`======================================================\n`);
    return;
  }

  const mailOptions = {
    from: `"GoWithUs App" <${process.env.SMTP_USER}>`,
    to: to,
    subject: 'รหัสยืนยันอีเมลของคุณ (GoWithUs)',
    html: `
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
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`✅ Verification email sent to ${to}`);
  } catch (error) {
    console.error(`❌ Error sending email to ${to}:`, error);
    throw new Error('Failed to send verification email');
  }
};
