import axios from 'axios';

// Never queue AI work on the API server. Normal routes do not use this gate.
const MAX_ACTIVE_AI_REQUESTS = 2;
const AI_TIMEOUT_MS = 90_000;
const AI_RETRY_DELAY_MS = 60_000;
const activeUsers = new Set();
let activeAIRequests = 0;
let retryAfter = 0;

const unavailable = (res, code, message, retrySeconds) => {
    res.setHeader('Retry-After', String(retrySeconds));
    return res.status(503).json({ error: message, code });
};

export const chatWithGemini = async (req, res, next) => {
    const { contents, generationConfig } = req.body || {};
    const apiKey = process.env.GEMINI_API_KEY || process.env.VITE_GEMINI_API_KEY;
    const model = process.env.GEMINI_MODEL || 'gemini-flash-latest';
    const userId = req.user?.userId;

    if (!contents || !Array.isArray(contents)) {
        return res.status(400).json({ error: 'Contents array is required' });
    }
    if (!apiKey) {
        return unavailable(res, 'AI_UNAVAILABLE', 'AI ไม่พร้อมใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง', 60);
    }
    if (Date.now() < retryAfter) {
        return unavailable(res, 'AI_UNAVAILABLE', 'AI ไม่พร้อมใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง', Math.max(1, Math.ceil((retryAfter - Date.now()) / 1000)));
    }
    if (activeAIRequests >= MAX_ACTIVE_AI_REQUESTS || (userId && activeUsers.has(userId))) {
        return unavailable(res, 'AI_BUSY', 'AI กำลังประมวลผลคำขออื่น กรุณาลองใหม่ภายหลัง', 5);
    }

    activeAIRequests += 1;
    if (userId) activeUsers.add(userId);
    try {
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

        const response = await axios.post(url, {
            contents,
            ...(generationConfig && { generationConfig })
        }, {
            timeout: AI_TIMEOUT_MS,
            signal: AbortSignal.timeout(AI_TIMEOUT_MS),
            maxBodyLength: 256 * 1024,
            maxContentLength: 1024 * 1024,
            headers: { 'Content-Type': 'application/json' }
        });

        res.json(response.data);
    } catch (error) {
        const upstreamStatus = error.response?.status;
        const timedOut = ['ECONNABORTED', 'ETIMEDOUT', 'ERR_CANCELED'].includes(error.code);
        // A slow individual generation must not disable AI for all users.
        if (upstreamStatus === 429 || upstreamStatus >= 500) {
            retryAfter = Date.now() + AI_RETRY_DELAY_MS;
        }
        // Do not expose upstream payloads, request contents, or API keys.
        console.warn('Gemini proxy unavailable', { status: upstreamStatus, code: error.code });
        const message = timedOut
            ? 'AI ตอบกลับช้าเกินไป กรุณาลองใหม่ภายหลัง ส่วนอื่นของแอปยังใช้งานได้'
            : 'AI ไม่พร้อมใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง ส่วนอื่นของแอปยังใช้งานได้';
        return unavailable(res, timedOut ? 'AI_TIMEOUT' : 'AI_UNAVAILABLE', message,
            Math.max(1, Math.ceil((retryAfter - Date.now()) / 1000)));
    } finally {
        activeAIRequests -= 1;
        if (userId) activeUsers.delete(userId);
    }
};
