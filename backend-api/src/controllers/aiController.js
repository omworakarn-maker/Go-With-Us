import axios from 'axios';

// Never queue AI work on the API server. Normal routes do not use this gate.
const MAX_ACTIVE_AI_REQUESTS = 2;
const AI_TIMEOUT_MS = 90_000;
const AI_RETRY_DELAY_MS = 60_000;
const activeUsers = new Set();
let activeAIRequests = 0;
let retryAfter = 0;
let groqRetryAfter = 0;

const isTimeout = error => ['ECONNABORTED', 'ETIMEDOUT', 'ERR_CANCELED'].includes(error.code);
const canFallback = error => !error.response?.status || isTimeout(error) ||
    error.response.status === 429 || error.response.status >= 500;

async function requestGroq(contents, generationConfig, apiKey) {
    const messages = contents.map(content => ({
        role: content.role === 'model' ? 'assistant' : 'user',
        content: content.parts.map(part => part.text).join('\n')
    }));
    const jsonMode = generationConfig?.responseMimeType === 'application/json';
    if (jsonMode) messages.unshift({
        role: 'system',
        content: 'Return only a valid JSON object matching the structure requested by the user. Do not use markdown.'
    });
    const response = await axios.post('https://api.groq.com/openai/v1/chat/completions', {
        model: process.env.GROQ_MODEL || 'openai/gpt-oss-20b',
        messages,
        max_completion_tokens: Math.min(8192, Math.max(256, Number(generationConfig?.maxOutputTokens) || 4096)),
        ...(Number.isFinite(generationConfig?.temperature) && { temperature: generationConfig.temperature }),
        ...(jsonMode && { response_format: { type: 'json_object' } })
    }, {
        timeout: 15_000,
        signal: AbortSignal.timeout(15_000),
        maxBodyLength: 256 * 1024,
        maxContentLength: 1024 * 1024,
        headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' }
    });
    const choice = response.data?.choices?.[0];
    const text = choice?.message?.content;
    if (typeof text !== 'string' || !text.trim() || choice.finish_reason === 'length') {
        throw Object.assign(new Error('Incomplete Groq response'), { code: 'INVALID_AI_RESPONSE' });
    }
    if (jsonMode) {
        try {
            const object = JSON.parse(text);
            if (!object || Array.isArray(object) || typeof object !== 'object') throw new Error();
        } catch {
            throw Object.assign(new Error('Invalid Groq JSON response'), { code: 'INVALID_AI_RESPONSE' });
        }
    }
    // Preserve the Gemini response contract used by both web and native clients.
    return { candidates: [{ content: { role: 'model', parts: [{ text }] }, finishReason: 'STOP' }] };
}

const unavailable = (res, code, message, retrySeconds) => {
    res.setHeader('Retry-After', String(retrySeconds));
    return res.status(503).json({ error: message, code });
};

export const chatWithGemini = async (req, res, next) => {
    const { contents, generationConfig } = req.body || {};
    const apiKey = process.env.GEMINI_API_KEY || process.env.VITE_GEMINI_API_KEY;
    const groqKey = process.env.GROQ_API_KEY;
    const model = process.env.GEMINI_MODEL || 'gemini-flash-latest';
    const userId = req.user?.userId;

    if (!Array.isArray(contents) || !contents.length || contents.some(content =>
        !content || !['user', 'model'].includes(content.role) ||
        !Array.isArray(content.parts) || !content.parts.length ||
        content.parts.some(part => !part || typeof part.text !== 'string')
    )) {
        return res.status(400).json({ error: 'Contents array is required' });
    }
    if (!apiKey && !groqKey) {
        return unavailable(res, 'AI_UNAVAILABLE', 'AI ไม่พร้อมใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง', 60);
    }
    if (Date.now() < retryAfter && (!groqKey || Date.now() < groqRetryAfter)) {
        return unavailable(res, 'AI_UNAVAILABLE', 'AI ไม่พร้อมใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง', Math.max(1, Math.ceil((retryAfter - Date.now()) / 1000)));
    }
    if (activeAIRequests >= MAX_ACTIVE_AI_REQUESTS || (userId && activeUsers.has(userId))) {
        return unavailable(res, 'AI_BUSY', 'AI กำลังประมวลผลคำขออื่น กรุณาลองใหม่ภายหลัง', 5);
    }

    activeAIRequests += 1;
    if (userId) activeUsers.add(userId);
    try {
        if (!apiKey || Date.now() < retryAfter) {
            if (!groqKey || Date.now() < groqRetryAfter) {
                return unavailable(res, 'AI_UNAVAILABLE', 'AI ไม่พร้อมใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง', 60);
            }
            try {
                return res.json(await requestGroq(contents, generationConfig, groqKey));
            } catch (error) {
                if (canFallback(error)) groqRetryAfter = Date.now() + AI_RETRY_DELAY_MS;
                throw error;
            }
        }
        const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

        let response;
        try {
        response = await axios.post(url, {
            contents,
            ...(generationConfig && { generationConfig })
        }, {
            // Existing web clients stop waiting after 30s. Reserve time for
            // the fallback without requiring a web or native client update.
            timeout: groqKey ? 12_000 : AI_TIMEOUT_MS,
            signal: AbortSignal.timeout(groqKey ? 12_000 : AI_TIMEOUT_MS),
            maxBodyLength: 256 * 1024,
            maxContentLength: 1024 * 1024,
            headers: { 'Content-Type': 'application/json' }
        });
        } catch (error) {
            if (error.response?.status === 429 || error.response?.status >= 500) {
                retryAfter = Date.now() + AI_RETRY_DELAY_MS;
            }
            if (!groqKey || Date.now() < groqRetryAfter || !canFallback(error)) throw error;
            console.warn('Trying Groq fallback', { status: error.response?.status, code: error.code });
            try {
                return res.json(await requestGroq(contents, generationConfig, groqKey));
            } catch (fallbackError) {
                if (canFallback(fallbackError)) groqRetryAfter = Date.now() + AI_RETRY_DELAY_MS;
                // Keep the providers' cooldowns independent.
                const timedOut = isTimeout(fallbackError);
                console.warn('Groq fallback unavailable', { status: fallbackError.response?.status, code: fallbackError.code });
                return unavailable(res, timedOut ? 'AI_TIMEOUT' : 'AI_UNAVAILABLE',
                    'AI ไม่พร้อมใช้งานชั่วคราว กรุณาลองใหม่ภายหลัง ส่วนอื่นของแอปยังใช้งานได้', 60);
            }
        }

        res.json(response.data);
    } catch (error) {
        const timedOut = isTimeout(error);
        // A slow individual generation must not disable AI for all users.
        // Do not expose upstream payloads, request contents, or API keys.
        console.warn('AI proxy unavailable', { status: error.response?.status, code: error.code });
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
