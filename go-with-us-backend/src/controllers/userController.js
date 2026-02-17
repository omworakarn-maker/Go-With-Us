import bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';
import { generateEmbedding } from '../utils/gemini.js';

const prisma = new PrismaClient();

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
                role: true,
                gender: true,
                age: true,
                bio: true,
                birthDate: true,
                profileImage: true,
                interests: true, // Included interests
                createdAt: true,
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
        const { name, password, interests, gender, age, bio, birthDate, profileImage } = req.body;

        const updateData = {};
        if (name) updateData.name = name;
        if (gender) updateData.gender = gender;
        if (age !== undefined && age !== null) updateData.age = parseInt(age);
        if (bio) updateData.bio = bio;
        if (birthDate) updateData.birthDate = new Date(birthDate);
        if (profileImage !== undefined) updateData.profileImage = profileImage || null;

        if (interests) {
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
                role: true,
                gender: true,
                age: true,
                bio: true,
                birthDate: true,
                profileImage: true,
                interests: true
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
