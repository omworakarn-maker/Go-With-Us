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
                role: true,
                gender: true,
                age: true,
                bio: true,
                birthDate: true,
                profileImage: true,
                gallery: true,
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
                isVerified: true,
                verificationStatus: true,
                username: true,
                usernameUpdatedAt: true,
                trips: {
                    orderBy: { createdAt: 'desc' },
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
        let userId = req.user.userId;
        const { targetId } = req.params;

        // If targetId is provided, check if requester is admin
        if (targetId && targetId !== userId) {
            if (req.user.role !== 'admin') {
                return res.status(403).json({ message: 'Access denied. Admin only.' });
            }
            userId = targetId;
        }
        const { name, username, password, interests, travelStyle, gender, age, bio, birthDate, profileImage, gallery } = req.body;

        const updateData = {};

        // Username Logic: Allow setting once if null, or allow change if > 30 days
        if (username !== undefined && username !== null && username !== "") {
            const currentUser = await prisma.user.findUnique({
                where: { id: userId },
                select: { username: true, usernameUpdatedAt: true }
            });

            if (currentUser.username && currentUser.username !== username) {
                // If they already have a username, check the 30-day limit
                if (currentUser.usernameUpdatedAt) {
                    const thirtyDaysAgo = new Date();
                    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

                    if (currentUser.usernameUpdatedAt > thirtyDaysAgo) {
                        return res.status(400).json({
                            message: 'คุณสามารถเปลี่ยน username ได้ทุกๆ 30 วันเท่านั้น'
                        });
                    }
                }

                // Check uniqueness if changed
                const existing = await prisma.user.findUnique({ where: { username } });
                if (existing) {
                    return res.status(400).json({ message: 'Username นี้มีผู้ใช้งานแล้ว' });
                }

                updateData.username = username;
                updateData.usernameUpdatedAt = new Date();
            } else if (!currentUser.username) {
                // First time setting username
                const existing = await prisma.user.findUnique({ where: { username } });
                if (existing) {
                    return res.status(400).json({ message: 'Username นี้มีผู้ใช้งานแล้ว' });
                }
                updateData.username = username;
                updateData.usernameUpdatedAt = new Date();
            }
        }

        // iOS sends null for missing optionals — only update if a real value is present
        if (name !== undefined && name !== null) updateData.name = name;
        if (gender !== undefined && gender !== null) updateData.gender = gender === '' ? null : gender;
        if (age !== undefined && age !== null) updateData.age = age !== '' ? parseInt(age) : null;
        if (bio !== undefined && bio !== null) updateData.bio = bio === '' ? null : bio;
        if (birthDate !== undefined && birthDate !== null) updateData.birthDate = new Date(birthDate);
        if (profileImage !== undefined && profileImage !== null) updateData.profileImage = profileImage === '' ? null : profileImage;
        if (gallery !== undefined) updateData.gallery = gallery;

        if (interests !== undefined || travelStyle !== undefined) {
            if (interests !== undefined) updateData.interests = interests;
            if (travelStyle !== undefined) updateData.travelStyle = travelStyle;

            // Generate AI Vector from interests and travel style
            // We fetch the current ones if only one is updated to have a complete profile for embedding
            const currentUser = await prisma.user.findUnique({ where: { id: userId }, select: { interests: true, travelStyle: true } });

            const combinedInterests = interests !== undefined ? interests : (currentUser?.interests || []);
            const combinedStyle = travelStyle !== undefined ? travelStyle : (currentUser?.travelStyle || {});
            
            // Format into narrative text for better semantic AI embedding
            const narrativeParts = [];
            narrativeParts.push(`This user enjoys: ${combinedInterests.join(', ') || 'general traveling'}.`);
            
            if (combinedStyle.activityStyle !== undefined) narrativeParts.push(`Their preferred activity level is ${combinedStyle.activityStyle} out of 10.`);
            if (combinedStyle.budget !== undefined) narrativeParts.push(`Their travel budget level is ${combinedStyle.budget} out of 10.`);
            if (combinedStyle.timeOfDay && combinedStyle.timeOfDay.length > 0) {
                narrativeParts.push(`They prefer traveling during the following times: ${combinedStyle.timeOfDay.join(', ')}.`);
            }
            
            const narrativeText = narrativeParts.join(' ');

            const vector = await generateEmbedding(narrativeText);

            if (vector) {
                updateData.embedding = vector;
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
                gallery: true,
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
                username: true,
                usernameUpdatedAt: true
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
                gallery: true,
                interests: true,
                createdAt: true,
                isProfilePublic: true,
                showGender: true,
                showAge: true,
                showBio: true,
                showInterests: true,
                showEmail: true,
                email: true,
                username: true,
                usernameUpdatedAt: true,
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
            username: user.username,
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
                username: true,
                email: true, // Maybe don't expose email publicly? Keeping it for now as unique ID reference
                profileImage: true,
            },
            orderBy: { name: 'asc' }
        });

        res.json(users);
    } catch (error) {
        console.error('Get all users error:', error);
        res.status(500).json({ message: 'Error fetching users' });
    }
};

// Admin dashboard summary
export const getAdminOverview = async (req, res) => {
    try {
        const admin = await prisma.user.findUnique({ where: { id: req.user.userId } });
        if (!admin || admin.role !== 'admin') {
            return res.status(403).json({ error: 'Admin access required' });
        }

        const [totalUsers, bannedUsers, verifiedUsers, pendingVerifications, pendingReports, totalTrips] = await Promise.all([
            prisma.user.count(),
            prisma.user.count({ where: { isBanned: true } }),
            prisma.user.count({ where: { isVerified: true } }),
            prisma.user.count({ where: { verificationStatus: 'pending' } }),
            prisma.report.count({ where: { status: 'pending' } }),
            prisma.trip.count(),
        ]);

        res.json({ totalUsers, bannedUsers, verifiedUsers, pendingVerifications, pendingReports, totalTrips });
    } catch (error) {
        console.error('Get admin overview error:', error);
        res.status(500).json({ error: 'Error fetching admin overview' });
    }
};

// Full user list for administration
export const getAdminUsers = async (req, res) => {
    try {
        const admin = await prisma.user.findUnique({ where: { id: req.user.userId } });
        if (!admin || admin.role !== 'admin') {
            return res.status(403).json({ error: 'Admin access required' });
        }

        const { search = '', status = 'all' } = req.query;
        const where = {
            ...(search ? {
                OR: [
                    { name: { contains: search, mode: 'insensitive' } },
                    { email: { contains: search, mode: 'insensitive' } },
                    { username: { contains: search, mode: 'insensitive' } },
                ]
            } : {}),
            ...(status === 'banned' ? { isBanned: true } : {}),
            ...(status === 'verified' ? { isVerified: true } : {}),
            ...(status === 'active' ? { isBanned: false } : {}),
        };

        const users = await prisma.user.findMany({
            where,
            orderBy: { createdAt: 'desc' },
            select: {
                id: true, name: true, username: true, email: true, role: true,
                profileImage: true, isBanned: true, isVerified: true,
                verificationStatus: true, createdAt: true,
                _count: { select: { trips: true, joinedTrips: true, reportsReceived: true } },
            },
        });

        res.json({ users, count: users.length });
    } catch (error) {
        console.error('Get admin users error:', error);
        res.status(500).json({ error: 'Error fetching users for administration' });
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

        // Check uniqueness in DB
        const existing = await prisma.user.findUnique({ where: { username } });

        if (existing && existing.id !== excludeUserId) {
            return res.json({ available: false, message: 'username นี้ถูกใช้งานแล้ว' });
        }

        res.json({ available: true, message: 'username นี้สามารถใช้งานได้' });
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

        // Resolve all pending reports for this user
        if (isBanned) {
            await prisma.report.updateMany({
                where: { reportedId: targetId, status: 'pending' },
                data: { status: 'resolved' }
            });
        }

        res.status(200).json({ message: `User ${isBanned ? 'banned' : 'unbanned'} successfully`, isBanned: updatedUser.isBanned });
    } catch (error) {
        console.error('Error banning user:', error);
        res.status(500).json({ error: 'Server error while banning/unbanning user' });
    }
};

// Warn a user (Admin only)
export const warnUser = async (req, res) => {
    try {
        const { userId: adminId } = req.user;
        const { targetId } = req.params;
        const { message } = req.body;

        if (!message) {
            return res.status(400).json({ error: 'Warning message is required' });
        }

        // Verify admin
        const admin = await prisma.user.findUnique({ where: { id: adminId } });
        if (!admin || admin.role !== 'admin') {
            return res.status(403).json({ error: 'Admin access required' });
        }

        // Create warning notification
        await prisma.notification.create({
            data: {
                title: 'คำเตือนจากผู้ดูแลระบบ',
                message,
                type: 'system',
                userId: targetId,
                targetId: 'admin_warning'
            }
        });

        // Resolve all pending reports for this user after warning
        await prisma.report.updateMany({
            where: { reportedId: targetId, status: 'pending' },
            data: { status: 'resolved' }
        });

        res.status(200).json({ message: 'Warning sent successfully' });
    } catch (error) {
        console.error('Error warning user:', error);
        res.status(500).json({ error: 'Server error while warning user' });
    }
};

// Get all reports (Admin only)
export const getAllReports = async (req, res) => {
    try {
        const { userId: adminId } = req.user;

        // Verify admin
        const admin = await prisma.user.findUnique({ where: { id: adminId } });
        if (!admin || admin.role !== 'admin') {
            return res.status(403).json({ error: 'Admin access required' });
        }

        const reports = await prisma.report.findMany({
            where: { status: 'pending' },
            orderBy: { createdAt: 'desc' },
            include: {
                reporter: {
                    select: { id: true, name: true, email: true, profileImage: true }
                },
                reported: {
                    select: { id: true, name: true, email: true, profileImage: true, isBanned: true }
                }
            }
        });

        res.json({ reports });
    } catch (error) {
        console.error('Error getting reports:', error);
        res.status(500).json({ error: 'Server error while getting reports' });
    }
};

// ==================== Identity Verification System ====================

// User requests verification by submitting images
export const requestVerification = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { idCardImage, faceScanImage } = req.body;

        if (!idCardImage || !faceScanImage) {
            return res.status(400).json({ error: 'Both ID Card and Face Scan images are required' });
        }

        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: {
                idCardImage,
                faceScanImage,
                verificationStatus: 'pending'
            }
        });

        res.json({ message: 'Verification requested successfully', status: updatedUser.verificationStatus });
    } catch (error) {
        console.error('Error requesting verification:', error);
        res.status(500).json({ error: 'Server error while requesting verification' });
    }
};

// Admin gets all pending verification requests
export const getVerificationRequests = async (req, res) => {
    try {
        const { userId: adminId } = req.user;

        // Verify admin
        const admin = await prisma.user.findUnique({ where: { id: adminId } });
        if (!admin || admin.role !== 'admin') {
            return res.status(403).json({ error: 'Admin access required' });
        }

        const requests = await prisma.user.findMany({
            where: { verificationStatus: 'pending' },
            select: {
                id: true,
                name: true,
                email: true,
                profileImage: true,
                idCardImage: true,
                faceScanImage: true,
                createdAt: true
            },
            orderBy: { createdAt: 'desc' }
        });

        res.json({ requests });
    } catch (error) {
        console.error('Error getting verification requests:', error);
        res.status(500).json({ error: 'Server error while getting requests' });
    }
};

// Admin approves or rejects a verification request
export const verifyUser = async (req, res) => {
    try {
        const { userId: adminId } = req.user;
        const { targetId } = req.params;
        const { status } = req.body; // 'verified' or 'rejected'

        if (!['verified', 'rejected', 'unverified'].includes(status)) {
            return res.status(400).json({ error: 'Invalid verification status' });
        }

        // Verify admin
        const admin = await prisma.user.findUnique({ where: { id: adminId } });
        if (!admin || admin.role !== 'admin') {
            return res.status(403).json({ error: 'Admin access required' });
        }

        const data = {
            verificationStatus: status,
            isVerified: status === 'verified'
        };

        // If rejected, maybe clear the images so they have to upload again
        if (status === 'rejected') {
            data.idCardImage = null;
            data.faceScanImage = null;
        }

        const updatedUser = await prisma.user.update({
            where: { id: targetId },
            data
        });

        // Notify the user about their verification status
        let notifMessage = status === 'verified'
            ? 'ยินดีด้วย! บัญชีของคุณได้รับการยืนยันตัวตนเรียบร้อยแล้ว'
            : 'การยืนยันตัวตนของคุณถูกปฏิเสธ โปรดอัปโหลดรูปภาพที่ชัดเจนอีกครั้ง';

        await prisma.notification.create({
            data: {
                title: 'สถานะการยืนยันตัวตน',
                message: notifMessage,
                type: 'system',
                userId: targetId
            }
        });

        res.json({ message: `User verification marked as ${status}`, isVerified: updatedUser.isVerified });
    } catch (error) {
        console.error('Error verifying user:', error);
        res.status(500).json({ error: 'Server error while verifying user' });
    }
};

