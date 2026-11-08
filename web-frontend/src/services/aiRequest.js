// AI requests are local to the AI feature: no global loader or authentication changes.
const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

export async function generateAIText(prompt, generationConfig) {
  const token = localStorage.getItem('authToken');
  if (!token) throw new Error('กรุณาเข้าสู่ระบบก่อนใช้ AI');

  const controller = new AbortController();
  const deadline = setTimeout(() => controller.abort(), 30_000);
  try {
    const response = await fetch(`${API_BASE_URL}/ai/chat`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`
      },
      signal: controller.signal,
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        ...(generationConfig ? { generationConfig } : {})
      })
    });
    const data = await response.json();
    if (!response.ok) {
      throw new Error(data.error || 'AI ไม่พร้อมใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง');
    }
    const text = data.candidates?.[0]?.content?.parts
      ?.map(part => part.text || '').join('').trim();
    if (!text) throw new Error('AI ไม่ได้ส่งคำตอบกลับมา กรุณาลองใหม่ภายหลัง');
    return text;
  } catch (error) {
    if (controller.signal.aborted) {
      throw new Error('AI ตอบกลับช้าเกินไป กรุณาลองใหม่ภายหลัง');
    }
    if (error instanceof TypeError || error instanceof SyntaxError) {
      throw new Error('เชื่อมต่อ AI ไม่สำเร็จ กรุณาลองใหม่ภายหลัง');
    }
    throw error;
  } finally {
    clearTimeout(deadline);
  }
}
