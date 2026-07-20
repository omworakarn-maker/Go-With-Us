import express from 'express';
import { register, login, getCurrentUser, verifyOTP, resendOTP } from '../controllers/authController.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/verify-otp', verifyOTP);
router.post('/resend-otp', resendOTP);

// Protected routes
router.get('/me', verifyToken, getCurrentUser);

export default router;
