import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { getProfile, updateProfile, getAllUsers, registerDeviceToken, getPublicProfile, updatePrivacySettings, checkUsername, reportUser, banUser } from '../controllers/userController.js';

const router = express.Router();

// Public routes - No auth needed
router.get('/check-username', checkUsername);
router.get('/:userId/public', getPublicProfile);

// Protected routes
router.use(verifyToken);

router.get('/', getAllUsers); // New route for searching users
router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.put('/privacy-settings', updatePrivacySettings);
router.post('/device-token', registerDeviceToken);

// Moderation routes
router.post('/:targetId/report', reportUser);
router.post('/:targetId/ban', banUser);

export default router;
