import express from 'express';
import { verifyToken } from '../middleware/auth.js';
import { getProfile, updateProfile, getAllUsers, getAdminOverview, getAdminUsers, registerDeviceToken, getPublicProfile, updatePrivacySettings, checkUsername, reportUser, banUser, warnUser, getAllReports, requestVerification, getVerificationRequests, verifyUser, resetAccount, deleteAccount } from '../controllers/userController.js';

const router = express.Router();

// Public routes - No auth needed
router.get('/check-username', checkUsername);
router.get('/:userId/public', getPublicProfile);

// Protected routes
router.use(verifyToken);

router.get('/admin/overview', getAdminOverview);
router.get('/admin/users', getAdminUsers);
router.get('/', getAllUsers); // New route for searching users
router.get('/profile', getProfile);
router.put('/profile', updateProfile);
router.put('/:targetId/profile', updateProfile); // Admin can use this to edit others
router.put('/privacy-settings', updatePrivacySettings);
router.post('/device-token', registerDeviceToken);
router.post('/account/reset', resetAccount);
router.delete('/account', deleteAccount);

// Moderation routes
router.post('/:targetId/report', reportUser);
router.post('/:targetId/ban', banUser);
router.post('/:targetId/warn', warnUser);
router.get('/reports/all', getAllReports);

// Identity Verification routes
router.post('/verify/request', requestVerification);
router.get('/verify/requests', getVerificationRequests); // Admin only internally checked
router.post('/verify/:targetId', verifyUser); // Admin only internally checked

export default router;
