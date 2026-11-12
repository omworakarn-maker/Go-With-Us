import express from 'express';
import crypto from 'node:crypto';
import prisma from '../utils/prismaClient.js';
import { verifyToken, isAdmin } from '../middleware/auth.js';

const router = express.Router();
router.use(verifyToken);
router.use((req, res, next) => {
    res.setHeader('Cache-Control', 'no-store');
    next();
});
router.get('/', async (req, res, next) => {
    try {
        const rows = await prisma.$queryRaw`SELECT * FROM app_promotion WHERE enabled = true ORDER BY "updatedAt" DESC LIMIT 1`;
        const promotion = rows[0] || null;
        res.json({ promotion: promotion?.enabled ? promotion : null });
    } catch (error) { next(error); }
});
router.get('/settings', isAdmin, async (req, res, next) => {
    try {
        const rows = await prisma.$queryRaw`SELECT * FROM app_promotion ORDER BY "updatedAt" DESC`;
        res.json({ promotion: rows.find(row => row.enabled) || rows[0] || null, promotions: rows });
    } catch (error) { next(error); }
});
router.put('/settings', isAdmin, async (req, res, next) => {
    try {
        const { enabled, image, frequency, targetType, target, title } = req.body || {};
        const id = req.body.id || 'main';
        if (typeof id !== 'string' || id.length > 64) return res.status(400).json({ error: 'Invalid promotion ID.' });
        if (typeof enabled !== 'boolean' || !['daily', 'launch', 'once'].includes(frequency) ||
            !['none', 'url', 'trip'].includes(targetType) ||
            typeof image !== 'string' || typeof target !== 'string' ||
            typeof title !== 'string' || title.length > 120 || target.length > 2048 ||
            !/^data:image\/(jpeg|png);base64,[A-Za-z0-9+/=]+$/.test(image) ||
            image.length > 3 * 1024 * 1024) {
            return res.status(400).json({ error: 'Invalid promotion. Choose a JPEG/PNG image smaller than 2 MB.' });
        }
        if (targetType === 'url') {
            let url;
            try { url = new URL(target); } catch { /* validated below */ }
            if (!url || url.protocol !== 'https:' || url.username || url.password) {
                return res.status(400).json({ error: 'Use a valid HTTPS link.' });
            }
        }
        if (targetType === 'trip') {
            const trip = await prisma.trip.findUnique({ where: { id: target }, select: { isPublic: true } });
            if (!trip?.isPublic) return res.status(400).json({ error: 'Choose an existing public trip.' });
        }
        // A changed creative is a new campaign; toggling enabled preserves its frequency history.
        const previous = await prisma.$queryRaw`SELECT * FROM app_promotion WHERE id = ${id}`;
        const old = previous[0];
        const revision = old && old.image === image && old.frequency === frequency &&
            old.targetType === targetType && old.target === target && old.title === title
            ? old.revision : crypto.randomUUID();
        await prisma.$transaction(async tx => {
        // Serialize activations so concurrent administrators cannot enable two banners.
        await tx.$executeRaw`SELECT pg_advisory_xact_lock(734921)`;
        if (enabled) await tx.$executeRaw`UPDATE app_promotion SET enabled = false WHERE id <> ${id} AND enabled = true`;
        await tx.$executeRaw`
            INSERT INTO app_promotion (id, enabled, image, frequency, "targetType", target, title, revision)
            VALUES (${id}, ${enabled}, ${image}, ${frequency}, ${targetType}, ${target}, ${title}, ${revision})
            ON CONFLICT (id) DO UPDATE SET enabled = EXCLUDED.enabled, image = EXCLUDED.image,
            frequency = EXCLUDED.frequency, "targetType" = EXCLUDED."targetType",
            target = EXCLUDED.target, title = EXCLUDED.title, revision = EXCLUDED.revision,
            "updatedAt" = CURRENT_TIMESTAMP
        `;
        });
        res.json({ message: 'Promotion saved', id });
    } catch (error) { next(error); }
});
router.patch('/:id/enabled', isAdmin, async (req, res, next) => {
    try {
        const { enabled } = req.body || {};
        if (typeof enabled !== 'boolean') return res.status(400).json({ error: 'Enabled must be boolean.' });
        const rows = await prisma.$queryRaw`SELECT id FROM app_promotion WHERE id = ${req.params.id}`;
        if (!rows.length) return res.status(404).json({ error: 'Promotion not found.' });
        await prisma.$transaction(async tx => {
            await tx.$executeRaw`SELECT pg_advisory_xact_lock(734921)`;
            if (enabled) await tx.$executeRaw`UPDATE app_promotion SET enabled = false WHERE enabled = true`;
            await tx.$executeRaw`UPDATE app_promotion SET enabled = ${enabled}, "updatedAt" = CURRENT_TIMESTAMP WHERE id = ${req.params.id}`;
        });
        res.json({ message: 'Promotion status updated' });
    } catch (error) { next(error); }
});
export default router;
