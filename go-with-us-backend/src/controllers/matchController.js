
import prisma from '../utils/prismaClient.js';
import { cosineSimilarity } from '../utils/ai.js';

// Match Buddies (Find similar users)
export const findBuddy = async (req, res) => {
    try {
        const userId = req.user.userId;

        // 1. Get Current User
        const currentUser = await prisma.user.findUnique({
            where: { id: userId },
            select: { id: true, embedding: true, interests: true }
        });

        if (!currentUser) {
            return res.status(404).json({ error: 'User not found' });
        }

        if (!currentUser.embedding || !Array.isArray(currentUser.embedding)) {
            return res.json({
                message: 'Please update your interests to enable AI matching.',
                matches: []
            });
        }

        // 2. Get All Other Users
        // In production, use Vector DB (pgvector) for scalability.
        // For strict MVP with small user base, fetching all is acceptable.
        const users = await prisma.user.findMany({
            where: {
                id: { not: userId },
                embedding: { not: null } // Only users with embeddings
            },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                profileImage: true,
                interests: true,
                embedding: true,
                bio: true,
                gender: true,
                age: true
            }
        });

        // 3. Calculate Similarity
        const matches = users.map(user => {
            const similarity = cosineSimilarity(currentUser.embedding, user.embedding);
            return {
                ...user,
                embedding: undefined, // Don't send vector to frontend
                matchScore: Math.round(similarity * 100) // Convert to percentage
            };
        })
            .filter(u => u.matchScore > 0) // Filter out zero/negative matches
            .sort((a, b) => b.matchScore - a.matchScore)
            .slice(0, 20); // Top 20

        res.json({ matches });

    } catch (error) {
        console.error('Find Buddy Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

// Match Trips (Find trips matching user style)
export const matchTrips = async (req, res) => {
    try {
        const userId = req.user.userId;

        // 1. Get Current User
        const currentUser = await prisma.user.findUnique({
            where: { id: userId },
            select: { id: true, embedding: true, interests: true }
        });

        // 2. Get Active Trips
        const trips = await prisma.trip.findMany({
            where: {
                endDate: { gte: new Date() }, // Only future/ongoing trips
                embedding: { not: null }
            },
            include: {
                creator: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        role: true,
                        profileImage: true,
                    },
                },
                participants: {
                    select: {
                        id: true,
                        userId: true,
                        name: true,
                        interests: true,
                        joinedAt: true,
                        status: true,
                    },
                },
            }
        });

        let matches = [];

        // If user has no embedding, return new/popular trips as fallback
        if (!currentUser?.embedding) {
            matches = trips
                .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
                .slice(0, 10)
                .map(t => ({ ...t, matchScore: 0, reason: 'Newest' }));
        } else {
            // Calculate similarity
            matches = trips.map(trip => {
                const similarity = cosineSimilarity(currentUser.embedding, trip.embedding);

                // Bonus for matching specific interests (category)
                let bonus = 0;
                if (currentUser.interests.includes(trip.category)) {
                    bonus = 0.1; // +10%
                }

                return {
                    ...trip,
                    embedding: undefined,
                    matchScore: Math.round((similarity + bonus) * 100)
                };
            })
                .sort((a, b) => b.matchScore - a.matchScore)
                .slice(0, 20);
        }

        res.json({ matches });

    } catch (error) {
        console.error('Match Trips Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

// Like or Dislike a User
export const likeUser = async (req, res) => {
    try {
        const userId = req.user.userId;
        const { targetId, status } = req.body; // status: "like" or "dislike"

        if (!targetId || !['like', 'dislike'].includes(status)) {
            return res.status(400).json({ error: 'Invalid request' });
        }

        // Check if mutual like exists
        let isMutual = false;
        if (status === 'like') {
            const oppositeLike = await prisma.userMatch.findFirst({
                where: {
                    likerId: targetId,
                    likedId: userId,
                    status: 'like'
                }
            });

            if (oppositeLike) {
                isMutual = true;
                // Update opposite to mutual
                await prisma.userMatch.update({
                    where: { id: oppositeLike.id },
                    data: { isMutual: true }
                });

                // Also create a notification for the other user
                await prisma.notification.create({
                    data: {
                        userId: targetId,
                        title: "It's a Match! 🎉",
                        message: "คุณมีเพื่อนใหม่ที่แมตช์กันแล้ว เข้าไปทำความรู้จักกันเลย!",
                        type: "alert"
                    }
                });
            }
        }

        // Create or update match
        const match = await prisma.userMatch.upsert({
            where: {
                likerId_likedId: {
                    likerId: userId,
                    likedId: targetId
                }
            },
            update: { status, isMutual },
            create: {
                likerId: userId,
                likedId: targetId,
                status,
                isMutual
            }
        });

        res.json({ success: true, isMutual, match });

    } catch (error) {
        console.error('Like User Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};

// Get Mutual Matches (People you can chat with)
export const getMutualMatches = async (req, res) => {
    try {
        const userId = req.user.userId;

        const matches = await prisma.userMatch.findMany({
            where: {
                OR: [
                    { likerId: userId, isMutual: true },
                    { likedId: userId, isMutual: true }
                ]
            }
        });

        const otherUserIds = matches.map(m => m.likerId === userId ? m.likedId : m.likerId);

        const users = await prisma.user.findMany({
            where: { id: { in: otherUserIds } },
            select: {
                id: true,
                name: true,
                email: true,
                profileImage: true,
                interests: true,
                isVerified: true
            }
        });

        res.json({ matches: users });

    } catch (error) {
        console.error('Get Mutual Matches Error:', error);
        res.status(500).json({ error: 'Internal Server Error' });
    }
};
