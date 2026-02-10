import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { getProfile, updateProfile, getAllUsers, registerDeviceToken } from '../controllers/userController.js';

const router = express.Router();

// Protected routes
router.use(verifyToken);

router.get('/', getAllUsers); // New route for searching users
router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.post('/device-token', registerDeviceToken);

export default router;
