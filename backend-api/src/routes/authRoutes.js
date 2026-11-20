import { getSessions, revokeSession, logoutOthers, logout } from '../controllers/sessionController.js';
import express from 'express';
import { register, login, googleLogin, getCurrentUser, verifyOTP, resendOTP } from '../controllers/authController.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

// Public routes
router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.post('/verify-otp', verifyOTP);
router.post('/resend-otp', resendOTP);

// Protected routes
router.get('/me', verifyToken, getCurrentUser);
router.get('/sessions', verifyToken, getSessions);
router.delete('/sessions/others', verifyToken, logoutOthers);
router.delete('/sessions/:id', verifyToken, revokeSession);
router.post('/logout', verifyToken, logout);

export default router;
