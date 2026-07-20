/**
 * Send OTP Verification Email using Resend HTTP API
 * @param {string} to - Recipient email
 * @param {string} otp - 6-digit OTP code
 */
export const sendVerificationEmail = async (to, otp) => {
  const RESEND_API_KEY = process.env.RESEND_API_KEY;
  
  if (!RESEND_API_KEY) {
    console.log(`\n======================================================`);
    console.log(`📧 [MOCK EMAIL] To: ${to}`);
    console.log(`🔑 [MOCK OTP] Your verification code is: ${otp}`);
    console.log(`⚠️ [WARNING] RESEND_API_KEY is not set. Email not sent.`);
    console.log(`======================================================\n`);
    return;
  }

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
