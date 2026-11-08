
import axios from 'axios';
import dotenv from 'dotenv';
dotenv.config();

// Embeddings enhance matching but must not prevent normal writes.
const EMBEDDING_TIMEOUT_MS = 5_000;
const RETRY_AFTER_MS = 60_000;
let retryAfter = 0;
let embeddingInFlight = false;

/**
 * Generate embedding vector from text using Gemini
 * @param {string|string[]} text - Input text or array of strings (e.g., interests)
 * @returns {Promise<number[]>} - Embedding vector (array of numbers)
 */
export const generateEmbedding = async (text) => {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey || embeddingInFlight || Date.now() < retryAfter) return null;
    embeddingInFlight = true;

    try {
        let prompt = "";
        if (Array.isArray(text)) {
            prompt = `User interests are: ${text.join(', ')}. Create a profile vector for travel preferences.`;
        } else if (typeof text === 'object' && text !== null) {
            const { interests, travelStyle } = text;
            const interestsStr = Array.isArray(interests) ? interests.join(', ') : '';
            const styleStr = Object.entries(travelStyle || {})
                .map(([key, value]) => `${key}: ${value}`)
                .join(', ');
            prompt = `User interests: ${interestsStr}. Travel Style: ${styleStr}. Create a detailed vector for matching with similar trips.`;
        } else {
            prompt = text;
        }

        const { data } = await axios.post(
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-embedding-001:embedContent',
            {
                model: 'models/gemini-embedding-001',
                content: { parts: [{ text: prompt }] }
            },
            {
                headers: { 'x-goog-api-key': apiKey },
                timeout: EMBEDDING_TIMEOUT_MS,
                signal: AbortSignal.timeout(EMBEDDING_TIMEOUT_MS)
            }
        );
        const values = data?.embedding?.values;
        if (!Array.isArray(values) || values.length === 0 ||
            !values.every(value => typeof value === 'number' && Number.isFinite(value))) {
            throw new Error('Invalid embedding response');
        }
        return values;
    } catch (error) {
        retryAfter = Date.now() + RETRY_AFTER_MS;
        console.warn('Skipping optional AI embedding', {
            status: error.response?.status,
            code: error.code
        });
        return null;
    } finally {
        embeddingInFlight = false;
    }
};

/**
 * Analyze trip description to extract category and summary
 * (Optional: Used when creating a trip)
 */
export const analyzeTrip = async (description) => {
    // ... logic for trip analysis ...
    // For now we just focus on embedding
};
