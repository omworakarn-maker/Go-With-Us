
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
                // email: true, // Privacy?
                interests: true,
                embedding: true,
                // avatar: true
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
                creator: { select: { id: true, name: true } },
                participants: { select: { id: true } }
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
