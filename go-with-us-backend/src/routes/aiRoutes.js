import express from 'express';
import { chatWithGemini } from '../controllers/aiController.js';

import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

// POST /api/ai/chat (Protected)
router.post('/chat', verifyToken, chatWithGemini);

export default router;
