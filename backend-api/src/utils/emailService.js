/**
 * Send OTP verification email through SendGrid's HTTPS API.
 * @param {string} to - Recipient email
 * @param {string} otp - 6-digit OTP code
 */
export const sendVerificationEmail = async (to, otp) => {
  const apiKey = process.env.SENDGRID_API_KEY;
  const fromEmail = process.env.SENDGRID_FROM_EMAIL;

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

  if (!apiKey || !fromEmail) {
    console.warn('⚠️ Email is not configured. Set SENDGRID_API_KEY and SENDGRID_FROM_EMAIL.');
    throw new Error('Email service is not configured');
  }

  try {
    const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${apiKey}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email: to }] }],
        from: { email: fromEmail, name: 'GoWithUs' },
        subject: `GoWithUs OTP: ${otp}`,
        content: [{ type: 'text/html', value: htmlContent }]
      })
    });

    if (response.ok) {
      console.log(`✅ Verification email sent to ${to} via SendGrid.`);
    } else {
      const errorText = await response.text();
      console.error('❌ SendGrid API Error:', response.status, errorText);
      throw new Error(`SendGrid Error: HTTP ${response.status}`);
    }
  } catch (error) {
    console.error(`❌ Error sending email to ${to}:`, error);
    throw error;
  }
};
