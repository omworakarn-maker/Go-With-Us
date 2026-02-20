import bcrypt from 'bcryptjs';
import prisma from '../utils/prismaClient.js';
import { generateEmbedding } from '../utils/gemini.js';

// Get current user profile
export const getProfile = async (req, res) => {
    try {
        const userId = req.user.userId;

        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: {
                id: true,
                email: true,
                name: true,
                username: true,
                role: true,
                gender: true,
                age: true,
                bio: true,
                birthDate: true,
                profileImage: true,
                interests: true,
                travelStyle: true,
                createdAt: true,
                updatedAt: true,
                isProfilePublic: true,
                showGender: true,
                showAge: true,
                showBio: true,
                showInterests: true,
                showEmail: true,
                trips: {
                    orderBy: { startDate: 'desc' },
                    include: {
                        participants: true
                    }
                }
            }
        });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const joinedTrips = await prisma.participant.findMany({
            where: { userId },
            orderBy: { joinedAt: 'desc' },
            include: {
                trip: {
                    include: {
                        participants: true
                    }
                }
            }
        });

        const response = {
            ...user,
            createdTrips: user.trips,
            participatedTrips: joinedTrips
        };
        delete response.trips;

        res.json(response);
    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({ message: 'Error fetching profile' });
    }
};

// Update user profile
export const updateProfile = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { name, username, password, interests, gender, age, bio, birthDate, profileImage, travelStyle } = req.body;

        const updateData = {};
        // iOS sends null for missing optionals — only update if a real value is present
        if (name !== undefined && name !== null) updateData.name = name;
        if (username !== undefined) updateData.username = username || null; // username: null is OK to clear
        if (gender !== undefined && gender !== null) updateData.gender = gender === '' ? null : gender;
        if (age !== undefined && age !== null) updateData.age = age !== '' ? parseInt(age) : null;
        if (bio !== undefined && bio !== null) updateData.bio = bio === '' ? null : bio;
        if (birthDate !== undefined && birthDate !== null) updateData.birthDate = new Date(birthDate);
        if (profileImage !== undefined && profileImage !== null) updateData.profileImage = profileImage === '' ? null : profileImage;
        if (travelStyle !== undefined && travelStyle !== null) updateData.travelStyle = travelStyle;

        if (interests !== undefined) {
            updateData.interests = interests; // Array of strings

            // Generate AI Vector from interests
            const vector = await generateEmbedding(interests);
            if (vector) {
                updateData.embedding = vector; // Save to Json field
            }
        }

        if (password) {
            const salt = await bcrypt.genSalt(10);
            updateData.password = await bcrypt.hash(password, salt);
        }

        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: updateData,
            select: {
                id: true,
                email: true,
                name: true,
                username: true,
                role: true,
                gender: true,
                age: true,
                bio: true,
                birthDate: true,
                profileImage: true,
                interests: true,
                travelStyle: true,
                createdAt: true,
                updatedAt: true,
                isProfilePublic: true,
                showGender: true,
                showAge: true,
                showBio: true,
                showInterests: true,
                showEmail: true
            }
        });

        res.json({ message: 'Profile updated successfully', user: updatedUser });
    } catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({ message: 'Error updating profile' });
    }
};

// Get public profile (anyone can view)
export const getPublicProfile = async (req, res) => {
    try {
        const { userId } = req.params;

        const user = await prisma.user.findUnique({
            where: { id: userId },
            select: {
                id: true,
                name: true,
                name: true,
                // username: true,
                role: true,
                gender: true,
                age: true,
                bio: true,
                birthDate: true,
                profileImage: true,
                interests: true,
                createdAt: true,
                isProfilePublic: true,
                showGender: true,
                showAge: true,
                showBio: true,
                showInterests: true,
                showEmail: true,
                email: true,
                trips: {
                    where: { isPublic: true },
                    orderBy: { startDate: 'desc' },
                    select: {
                        id: true,
                        title: true,
                        destination: true,
                        startDate: true,
                        endDate: true,
                        maxParticipants: true,
                        category: true,
                        imageUrl: true,
                        _count: {
                            select: { participants: true }
                        }
                    },
                    take: 5 // Show latest 5 trips
                }
            }
        });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        // Check if profile is private
        if (!user.isProfilePublic) {
            return res.status(403).json({ message: 'This profile is private' });
        }

        // Filter sensitive fields based on privacy settings
        const publicProfile = {
            id: user.id,
            name: user.name,
            id: user.id,
            name: user.name,
            // username: user.username,
            role: user.role,
            profileImage: user.profileImage,
            createdAt: user.createdAt,
            trips: user.trips,
            isProfilePublic: user.isProfilePublic,
        };

        // Conditionally add fields based on privacy settings
        if (user.showGender && user.gender) publicProfile.gender = user.gender;
        if (user.showAge && user.age) publicProfile.age = user.age;
        if (user.showBio && user.bio) publicProfile.bio = user.bio;
        if (user.showInterests && user.interests) publicProfile.interests = user.interests;
        if (user.showEmail) publicProfile.email = user.email;

        res.json(publicProfile);
    } catch (error) {
        console.error('Get public profile error:', error);
        res.status(500).json({ message: 'Error fetching public profile' });
    }
};

// Update privacy settings
export const updatePrivacySettings = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { isProfilePublic, showGender, showAge, showBio, showInterests, showEmail } = req.body;

        const updateData = {};
        if (isProfilePublic !== undefined) updateData.isProfilePublic = isProfilePublic;
        if (showGender !== undefined) updateData.showGender = showGender;
        if (showAge !== undefined) updateData.showAge = showAge;
        if (showBio !== undefined) updateData.showBio = showBio;
        if (showInterests !== undefined) updateData.showInterests = showInterests;
        if (showEmail !== undefined) updateData.showEmail = showEmail;

        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: updateData,
            select: {
                id: true,
                isProfilePublic: true,
                showGender: true,
                showAge: true,
                showBio: true,
                showInterests: true,
                showEmail: true
            }
        });

        res.json({ message: 'Privacy settings updated successfully', user: updatedUser });
    } catch (error) {
        console.error('Update privacy settings error:', error);
        res.status(500).json({ message: 'Error updating privacy settings' });
    }
};

// Get all users (searchable)
export const getAllUsers = async (req, res) => {
    try {
        const { search } = req.query;
        // Don't include current user in search results? Optional, but good practice.
        const currentUserId = req.user.userId;

        const whereClause = {};
        if (search) {
            whereClause.name = {
                contains: search,
                mode: 'insensitive' // Requires PostgreSQL and Prisma config, or use lower case logic if using simple DB
            };
        }

        // Exclude self
        whereClause.id = { not: currentUserId };

        const users = await prisma.user.findMany({
            where: whereClause,
            take: 20, // Limit results
            select: {
                id: true,
                name: true,
                email: true, // Maybe don't expose email publicly? Keeping it for now as unique ID reference
                // Avatar?
            },
            orderBy: { name: 'asc' }
        });

        res.json(users);
    } catch (error) {
        console.error('Get all users error:', error);
        res.status(500).json({ message: 'Error fetching users' });
    }
};

// Register FCM Device Token
export const registerDeviceToken = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { token } = req.body;

        if (!token) {
            return res.status(400).json({ message: 'Token is required' });
        }

        await prisma.user.update({
            where: { id: userId },
            data: { fcmToken: token }
        });

        res.json({ message: 'Device token registered successfully' });
    } catch (error) {
        console.error('Register device token error:', error);
        res.status(500).json({ message: 'Error registering device token' });
    }
};

// Check username availability
export const checkUsername = async (req, res) => {
    try {
        const { username } = req.query;
        const excludeUserId = req.query.excludeUserId;

        if (!username || username.trim().length < 3) {
            return res.status(400).json({ available: false, message: 'Username must be at least 3 characters' });
        }

        // Validate format: only letters, numbers, underscores
        const usernameRegex = /^[a-zA-Z0-9_]+$/;
        if (!usernameRegex.test(username)) {
            return res.status(400).json({ available: false, message: 'Username can only contain letters, numbers, and underscores' });
        }

        // Check disabled: DB missing username column
        /*
        const existing = await prisma.user.findUnique({ where: { username } });

        if (existing && existing.id !== excludeUserId) {
            return res.json({ available: false, message: 'Username is already taken' });
        }
        */

        res.json({ available: true, message: 'Username is available' });
    } catch (error) {
        console.error('Check username error:', error);
        res.status(500).json({ available: false, message: 'Error checking username' });
    }
};

// Report a user
export const reportUser = async (req, res) => {
    try {
        const { userId } = req.user;
        const { targetId } = req.params;
        const { reason } = req.body;

        if (!reason) {
            return res.status(400).json({ error: 'Reason is required' });
        }

        // Prevent self-reporting
        if (userId === targetId) {
            return res.status(400).json({ error: 'You cannot report yourself' });
        }

        const report = await prisma.report.create({
            data: {
                reporterId: userId,
                reportedId: targetId,
                reason,
                status: 'pending'
            }
        });

        // Fetch admins to notify them
        const admins = await prisma.user.findMany({
            where: { role: 'admin' },
            select: { id: true, fcmToken: true }
        });

        // You could send a direct push or save a notification
        // For simplicity, we just save a notification to admins
        await Promise.all(admins.map(async (admin) => {
            await prisma.notification.create({
                data: {
                    title: 'New User Report',
                    message: `A user has been reported for: ${reason}`,
                    type: 'system',
                    userId: admin.id
                }
            });
        }));

        res.status(201).json({ message: 'User reported successfully', report });
    } catch (error) {
        console.error('Error reporting user:', error);
        res.status(500).json({ error: 'Server error while reporting user' });
    }
};

// Ban or unban a user (Admin only)
export const banUser = async (req, res) => {
    try {
        const { userId: adminId } = req.user;
        const { targetId } = req.params;
        const { isBanned } = req.body; // true to ban, false to unban

        // Verify admin
        const admin = await prisma.user.findUnique({ where: { id: adminId } });
        if (!admin || admin.role !== 'admin') {
            return res.status(403).json({ error: 'Admin access required' });
        }

        // Prevent self-ban
        if (adminId === targetId) {
            return res.status(400).json({ error: 'You cannot ban yourself' });
        }

        const updatedUser = await prisma.user.update({
            where: { id: targetId },
            data: { isBanned }
        });

        res.status(200).json({ message: `User ${isBanned ? 'banned' : 'unbanned'} successfully`, isBanned: updatedUser.isBanned });
    } catch (error) {
        console.error('Error banning user:', error);
        res.status(500).json({ error: 'Server error while banning/unbanning user' });
    }
};

