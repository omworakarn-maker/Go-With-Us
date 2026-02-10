
import express from 'express';
import { findBuddy, matchTrips } from '../controllers/matchController.js';
import { verifyToken } from '../middleware/auth.js';

const router = express.Router();

router.get('/buddy', verifyToken, findBuddy);
router.get('/trips', verifyToken, matchTrips);

export default router;
