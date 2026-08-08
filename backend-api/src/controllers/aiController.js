import axios from 'axios';

export const chatWithGemini = async (req, res, next) => {
    try {
        const { contents, generationConfig } = req.body;
        // Check both common env var names
        const apiKey = process.env.VITE_GEMINI_API_KEY || process.env.GEMINI_API_KEY;
        const model = "gemini-flash-latest"; // Verified stable model for 2026

        console.log('--- Gemini Proxy Request ---');
        console.log('Model:', model);
        console.log('Payload:', JSON.stringify(contents).substring(0, 100) + '...');

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
            headers: { 'Content-Type': 'application/json' }
        });

        console.log('✅ Gemini Response Success');
        res.json(response.data);
    } catch (error) {
        console.error('Gemini Proxy Error:', error.response?.data || error.message);
        res.status(error.response?.status || 500).json({
            error: 'Failed to communicate with Gemini API',
            details: error.response?.data || error.message
        });
    }
};
