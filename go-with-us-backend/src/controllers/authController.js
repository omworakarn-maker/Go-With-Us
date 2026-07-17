import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import prisma from '../utils/prismaClient.js';
import { sendVerificationEmail } from '../utils/emailService.js';
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

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

        // Check if user exists
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
        const otpExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

        // Create user
        const user = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                role: 'user', // Default role
                otpCode,
                otpExpiresAt,
                isEmailVerified: false
            },
        });
        
        // Send OTP via Email
        await sendVerificationEmail(email, otpCode);

        // Generate JWT token
        const token = jwt.sign(
            { userId: user.id, email: user.email, role: user.role },
            JWT_SECRET,
            { expiresIn: '7d' }
        );

        res.status(201).json({
            message: 'User registered successfully',
            token,
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                username: null,
                usernameUpdatedAt: null
            },
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
        if (user.isEmailVerified === false) {
            return res.status(401).json({ error: 'Please verify your email address before logging in.', needsVerification: true });
        }

        // Check password
        const isValidPassword = await bcrypt.compare(password, user.password);

        if (!isValidPassword) {
            return res.status(401).json({ error: 'Invalid email or password.' });
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
                profileImage: true,
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
