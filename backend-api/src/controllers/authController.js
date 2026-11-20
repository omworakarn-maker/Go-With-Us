import { createDeviceSession, SESSION_LIFETIME_SECONDS } from '../utils/deviceSessions.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { OAuth2Client } from 'google-auth-library';
import prisma from '../utils/prismaClient.js';
import { sendVerificationEmail } from '../utils/emailService.js';
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

const generateUniqueUsername = async (tx) => {
    for (let attempt = 0; attempt < 10; attempt += 1) {
        const candidate = `traveler_${crypto.randomBytes(4).toString('hex')}`;
        const existing = await tx.user.findUnique({ where: { username: candidate }, select: { id: true } });
        if (!existing) return candidate;
    }
    throw new Error('Unable to generate a unique username.');
};

// Register new user
export const register = async (req, res, next) => {
    try {
        const { name, email, password } = req.body;

        // Validation
        if (!name || !email || !password) {
            return res.status(400).json({ error: 'All fields are required.' });
        }

        if (typeof password !== 'string' || [...password].length < 8 || !/\p{L}/u.test(password)) {
            return res.status(400).json({ error: 'Password must be at least 8 characters and include at least one letter.' });
        }

        if (Buffer.byteLength(password, 'utf8') > 72) {
            return res.status(400).json({ error: 'Password must be at most 72 bytes.' });
        }

        // Only completed registrations exist in the users table.
        const existingUser = await prisma.user.findUnique({
            where: { email },
            select: { id: true }
        });

        if (existingUser) {
            return res.status(400).json({ error: 'Email already registered.' });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(password, 10);
        
        // Generate OTP
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        const otpHash = await bcrypt.hash(otpCode, 10);
        const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

        await prisma.pendingRegistration.upsert({
            where: { email },
            update: { name, passwordHash: hashedPassword, otpCode: otpHash, otpExpiresAt },
            create: { name, email, passwordHash: hashedPassword, otpCode: otpHash, otpExpiresAt }
        });

        await sendVerificationEmail(email, otpCode);

        res.status(202).json({
            message: 'OTP sent. Complete verification to create the account.',
            email,
            otpExpiresAt
        });
    } catch (error) {
        next(error);
    }
};

// Login user
export const login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        // Validation
        if (!email || !password) {
            return res.status(400).json({ error: 'Email and password are required.' });
        }

        // Find user
        const user = await prisma.user.findUnique({
            where: { email },
            select: {
                id: true,
                name: true,
                email: true,
                password: true,
                role: true,
                interests: true,
                profileImage: true,
                gallery: true,
                gender: true,
                age: true,
                bio: true,
                birthDate: true,
                createdAt: true,
                updatedAt: true,
                isProfilePublic: true,
                showGender: true,
                showAge: true,
                showBio: true,
                showInterests: true,
                showEmail: true,
                isBanned: true,
                isVerified: true,
                verificationStatus: true,
                isEmailVerified: true,
                username: true,
                usernameUpdatedAt: true,
            }
        });

        if (!user) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        if (user.isBanned) {
            return res.status(403).json({ error: 'บัญชีของคุณถูกระงับการใช้งาน โปรดติดต่อผู้ดูแลระบบ' });
        }
        
        // Ensure email is verified
        if (user.isEmailVerified === false && user.role !== 'admin') {
            return res.status(401).json({ error: 'Please verify your email address before logging in.', needsVerification: true });
        }

        // Check password
        const isValidPassword = await bcrypt.compare(password, user.password);

        if (!isValidPassword) {
            return res.status(401).json({ error: 'Invalid email or password.' });
        }

        // Admin roles are assigned by the system and do not use the end-user
        // email or face-verification flow.
        if (user.role === 'admin' && (!user.isEmailVerified || !user.isVerified || user.verificationStatus !== 'verified')) {
            await prisma.user.update({
                where: { id: user.id },
                data: {
                    isEmailVerified: true,
                    isVerified: true,
                    verificationStatus: 'verified'
                }
            });
            user.isEmailVerified = true;
            user.isVerified = true;
            user.verificationStatus = 'verified';
        }

        // Generate JWT token
        const session = await createDeviceSession(user.id, req);
        const token = jwt.sign(
            { userId: user.id, email: user.email, role: user.role, sid: session.id, sessionVersion: session.version },
            JWT_SECRET,
            { expiresIn: SESSION_LIFETIME_SECONDS }
        );

        res.json({
            message: 'Login successful',
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                interests: user.interests,
                profileImage: user.profileImage,
                gallery: user.gallery,
                gender: user.gender,
                age: user.age,
                bio: user.bio,
                birthDate: user.birthDate,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt,
                isProfilePublic: user.isProfilePublic,
                showGender: user.showGender,
                showAge: user.showAge,
                showBio: user.showBio,
                showInterests: user.showInterests,
                showEmail: user.showEmail,
                isVerified: user.isVerified,
                verificationStatus: user.verificationStatus,
                isEmailVerified: user.isEmailVerified,
                username: user.username,
                usernameUpdatedAt: user.usernameUpdatedAt,
            },
        });
    } catch (error) {
        next(error);
    }
};

let googleClient;
const googleUserFields = {
    id: true, name: true, email: true, role: true, isBanned: true, username: true,
    interests: true, profileImage: true, birthDate: true, travelStyle: true,
    isVerified: true, verificationStatus: true,
};

export const googleLogin = async (req, res, next) => {
    const audience = process.env.GOOGLE_WEB_CLIENT_ID?.trim();
    if (!audience) return res.status(503).json({ error: 'ยังไม่ได้เปิดใช้งานการเข้าสู่ระบบด้วย Google' });
    if (!req.is('application/json') || typeof req.body?.credential !== 'string' || !req.body.credential) {
        return res.status(400).json({ error: 'กรุณาเข้าสู่ระบบผ่านปุ่ม Google' });
    }

    let identity;
    try {
        googleClient ??= new OAuth2Client();
        const ticket = await googleClient.verifyIdToken({ idToken: req.body.credential, audience });
        identity = ticket.getPayload();
    } catch {
        return res.status(401).json({ error: 'ยืนยันบัญชี Google ไม่สำเร็จ กรุณาลองใหม่' });
    }

    if (!identity?.sub || !identity.email || identity.email_verified !== true) {
        return res.status(401).json({ error: 'กรุณาใช้บัญชี Google ที่ยืนยันอีเมลแล้ว' });
    }

    try {
        const email = identity.email.trim().toLowerCase();
        const subject = identity.sub;
        const emailConflict = () => res.status(409).json({ error: 'อีเมลนี้มีบัญชี GoWithUs อยู่แล้ว กรุณาเข้าสู่ระบบด้วยรหัสผ่าน' });
        let user = await prisma.user.findUnique({ where: { googleSubject: subject }, select: googleUserFields });

        if (!user) {
            if (!email.endsWith('@gmail.com') && !identity.hd) {
                return res.status(403).json({ error: 'กรุณาใช้ Gmail หรือบัญชี Google Workspace หรือสมัครด้วยอีเมล' });
            }
            const existing = await prisma.user.findFirst({
                where: { email: { equals: email, mode: 'insensitive' } }, select: { id: true },
            });
            if (existing) return emailConflict();

            // Preserve the required password column with an undisclosed random password.
            const password = await bcrypt.hash(crypto.randomBytes(32).toString('hex'), 10);
            try {
                user = await prisma.$transaction(async tx => tx.user.create({
                    data: {
                        name: identity.name?.trim().slice(0, 100) || email.split('@')[0],
                        email, password, googleSubject: subject, isEmailVerified: true,
                        username: await generateUniqueUsername(tx),
                    },
                    select: googleUserFields,
                }));
            } catch (error) {
                if (error.code !== 'P2002') throw error;
                user = await prisma.user.findUnique({ where: { googleSubject: subject }, select: googleUserFields });
                if (!user) {
                    const conflictingEmail = await prisma.user.findUnique({ where: { email }, select: { id: true } });
                    if (conflictingEmail) return emailConflict();
                    throw error;
                }
            }
        }

        if (user.isBanned || user.role !== 'user') {
            return res.status(403).json({ error: 'บัญชีนี้ไม่สามารถเข้าสู่ระบบด้วย Google ได้' });
        }

        const session = await createDeviceSession(user.id, req);
        const token = jwt.sign(
            { userId: user.id, email: user.email, role: user.role, sid: session.id, sessionVersion: session.version },
            JWT_SECRET,
            { expiresIn: SESSION_LIFETIME_SECONDS }
        );
        const { isBanned, birthDate, travelStyle, ...publicUser } = user;
        res.json({ token, user: publicUser, needsOnboarding: !birthDate || !user.profileImage || !travelStyle });
    } catch (error) {
        next(error);
    }
};

// Get current user (protected route)
export const getCurrentUser = async (req, res, next) => {
    try {
        const user = await prisma.user.findUnique({
            where: { id: req.user.userId },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                interests: true,
                travelStyle: true,
                profileImage: true,
                gallery: true,
                createdAt: true,
                updatedAt: true,
                gender: true,
                age: true,
                bio: true,
                birthDate: true,
                isProfilePublic: true,
                showGender: true,
                showAge: true,
                showBio: true,
                showInterests: true,
                showEmail: true,
                isBanned: true,
                isVerified: true,
                verificationStatus: true,
                isEmailVerified: true,
                username: true,
                usernameUpdatedAt: true
            },
        });

        if (!user) {
            return res.status(404).json({ error: 'User not found.' });
        }

        if (user.isBanned) {
            return res.status(403).json({ error: 'บัญชีของคุณถูกระงับการใช้งาน โปรดติดต่อผู้ดูแลระบบ' });
        }

        res.json({ user });
    } catch (error) {
        next(error);
    }
};

export const verifyOTP = async (req, res, next) => {
    try {
        const { email, otp } = req.body;
        
        if (!email || !otp) {
            return res.status(400).json({ error: 'Email and OTP are required.' });
        }
        
        const pending = await prisma.pendingRegistration.findUnique({ where: { email } });

        if (!pending) {
            return res.status(404).json({ error: 'No pending registration found.' });
        }

        if (!(await bcrypt.compare(otp, pending.otpCode))) {
            return res.status(400).json({ error: 'Invalid OTP.' });
        }

        if (pending.otpExpiresAt < new Date()) {
            return res.status(400).json({ error: 'OTP has expired. Please request a new one.' });
        }

        const user = await prisma.$transaction(async (tx) => {
            const generatedUsername = await generateUniqueUsername(tx);
            const createdUser = await tx.user.create({
                data: {
                    name: pending.name,
                    email: pending.email,
                    password: pending.passwordHash,
                    role: 'user',
                    isEmailVerified: true,
                    username: generatedUsername
                }
            });
            await tx.pendingRegistration.delete({ where: { email } });
            return createdUser;
        });

        const session = await createDeviceSession(user.id, req);
        const token = jwt.sign(
            { userId: user.id, email: user.email, role: user.role, sid: session.id, sessionVersion: session.version },
            JWT_SECRET,
            { expiresIn: SESSION_LIFETIME_SECONDS }
        );

        res.status(201).json({
            message: 'Email verified and account created successfully.',
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                username: user.username,
                usernameUpdatedAt: user.usernameUpdatedAt,
                isEmailVerified: user.isEmailVerified
            }
        });
    } catch (error) {
        next(error);
    }
};

export const resendOTP = async (req, res, next) => {
    try {
        const { email } = req.body;
        
        if (!email) {
            return res.status(400).json({ error: 'Email is required.' });
        }
        
        const pending = await prisma.pendingRegistration.findUnique({ where: { email } });

        if (!pending) {
            return res.status(404).json({ error: 'No pending registration found.' });
        }
        
        const otpCode = Math.floor(100000 + Math.random() * 900000).toString();
        const otpHash = await bcrypt.hash(otpCode, 10);
        const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000);
        
        await prisma.pendingRegistration.update({
            where: { email },
            data: { otpCode: otpHash, otpExpiresAt }
        });

        await sendVerificationEmail(email, otpCode);
        
        res.json({ message: 'OTP sent successfully.' });
    } catch (error) {
        next(error);
    }
};
