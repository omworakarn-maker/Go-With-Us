import axios from 'axios';

export const chatWithGemini = async (req, res, next) => {
    try {
        const { contents, generationConfig } = req.body || {};
        // Check both common env var names
        const apiKey = process.env.VITE_GEMINI_API_KEY || process.env.GEMINI_API_KEY;
        const model = "gemini-flash-latest"; // Verified stable model for 2026

        console.log('--- Gemini Proxy Request ---');
        console.log('Model:', model);

        if (!apiKey) {
            console.error('❌ Gemini API key is missing on server');
            return res.status(500).json({ error: 'Gemini API key is not configured on server' });
        }

        if (!contents || !Array.isArray(contents)) {
            return res.status(400).json({ error: 'Contents array is required' });
        }

        const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

        const response = await axios.post(url, {
            contents,
            ...(generationConfig && { generationConfig })
        }, {
            timeout: 20_000,
            signal: AbortSignal.timeout(20_000),
            headers: { 'Content-Type': 'application/json' }
        });

        console.log('✅ Gemini Response Success');
        res.json(response.data);
    } catch (error) {
        const upstreamStatus = error.response?.status;
        const timedOut = ['ECONNABORTED', 'ETIMEDOUT', 'ERR_CANCELED'].includes(error.code);
        // Do not expose upstream payloads, request contents, or API keys.
        console.warn('Gemini proxy unavailable', { status: upstreamStatus, code: error.code });
        const message = timedOut
            ? 'AI ตอบกลับช้าเกินไป กรุณาลองใหม่ภายหลัง ส่วนอื่นของแอปยังใช้งานได้'
            : 'AI ไม่พร้อมใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง ส่วนอื่นของแอปยังใช้งานได้';
        return res.status(503).json({
            error: message,
            code: timedOut ? 'AI_TIMEOUT' : 'AI_UNAVAILABLE'
        });
    }
};
