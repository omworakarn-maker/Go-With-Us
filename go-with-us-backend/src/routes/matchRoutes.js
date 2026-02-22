
import express from 'express';
import { findBuddy, matchTrips, likeUser, getMutualMatches } from '../controllers/matchController.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

router.get('/buddy', verifyToken, findBuddy);
router.get('/trips', verifyToken, matchTrips);
router.post('/buddy/like', verifyToken, likeUser);
router.get('/buddy/mutual', verifyToken, getMutualMatches);

export default router;
