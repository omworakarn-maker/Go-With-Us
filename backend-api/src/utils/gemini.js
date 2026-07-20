
import { GoogleGenerativeAI } from '@google/generative-ai';
import dotenv from 'dotenv';
dotenv.config();

// Initialize Gemini
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const model = genAI.getGenerativeModel({ model: "gemini-embedding-001" });

/**
 * Generate embedding vector from text using Gemini
 * @param {string|string[]} text - Input text or array of strings (e.g., interests)
 * @returns {Promise<number[]>} - Embedding vector (array of numbers)
 */
export const generateEmbedding = async (text) => {
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

        const result = await model.embedContent(prompt);
        const embedding = result.embedding;

        return embedding.values;
    } catch (error) {
        console.error('Gemini Embedding Error:', error);
        // Return mock embedding in dev mode if API fails (optional)
        // return new Array(768).fill(0).map(() => Math.random());
        return null; // Or throw error
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
