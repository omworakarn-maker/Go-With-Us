import axios from 'axios';

export const chatWithGemini = async (req, res, next) => {
    try {
        const { contents } = req.body;
        const apiKey = process.env.VITE_GEMINI_API_KEY;
        const model = "gemini-2.0-flash-lite"; // Preferred model

        if (!apiKey) {
            return res.status(500).json({ error: 'Gemini API key is not configured on server' });
        }

        if (!contents || !Array.isArray(contents)) {
            return res.status(400).json({ error: 'Contents array is required' });
        }

        const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;

        const response = await axios.post(url, { contents }, {
            headers: {
                'Content-Type': 'application/json',
            }
        });

        res.json(response.data);
    } catch (error) {
        console.error('Gemini Proxy Error:', error.response?.data || error.message);
        res.status(error.response?.status || 500).json({
            error: 'Failed to communicate with Gemini API',
            details: error.response?.data || error.message
        });
    }
};
