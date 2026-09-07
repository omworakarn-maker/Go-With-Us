import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
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

        if (password.length < 6) {
            return res.status(400).json({ error: 'Password must be at least 6 characters.' });
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
        const token = jwt.sign(
            { userId: user.id, email: user.email, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
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

        const token = jwt.sign(
            { userId: user.id, email: user.email, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
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
