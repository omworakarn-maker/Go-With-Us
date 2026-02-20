import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { getProfile, updateProfile, getAllUsers, registerDeviceToken, getPublicProfile, updatePrivacySettings, checkUsername } from '../controllers/userController.js';

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

export default router;
