import prisma from '../utils/prismaClient.js';

// Helper to normalize legacy and new travel styles
const normalizeTravelStyle = (style) => {
    if (!style || typeof style !== 'object') return null;
    
    let budget = null;
    if (style.budget !== undefined) {
        if (typeof style.budget === 'number') budget = style.budget;
        else if (style.budget === 'budget') budget = 2;
        else if (style.budget === 'moderate') budget = 5;
        else if (style.budget === 'luxury') budget = 8;
        else if (!isNaN(Number(style.budget))) budget = Number(style.budget);
    }
    
    let activityStyle = null;
    if (style.activityStyle !== undefined) {
        if (typeof style.activityStyle === 'number') activityStyle = style.activityStyle;
        else if (!isNaN(Number(style.activityStyle))) activityStyle = Number(style.activityStyle);
    } else if (style.pace !== undefined) {
        if (style.pace === 'relaxed') activityStyle = 2;
        else if (style.pace === 'moderate') activityStyle = 5;
        else if (style.pace === 'fast') activityStyle = 8;
    }
    
    let timeOfDay = [];
    if (Array.isArray(style.timeOfDay)) {
        timeOfDay = style.timeOfDay;
    }
    
    return { budget, activityStyle, timeOfDay };
};

// Helper to calculate exact user-to-user compatibility percentage
const calculateDetailedCompatibility = (userA, userB) => {
    const styleA = normalizeTravelStyle(userA.travelStyle);
    const styleB = normalizeTravelStyle(userB.travelStyle);

    let scores = [];
    
    // 1. Budget Level
    if (styleA && styleA.budget !== null && styleB && styleB.budget !== null) {
        const score = 1.0 - (Math.abs(styleA.budget - styleB.budget) / 9.0);
        scores.push(score);
    }

    // 2. Activity Style
    if (styleA && styleA.activityStyle !== null && styleB && styleB.activityStyle !== null) {
        const score = 1.0 - (Math.abs(styleA.activityStyle - styleB.activityStyle) / 9.0);
        scores.push(score);
    }

    // 3. Time of Day
    if (styleA && styleA.timeOfDay && styleA.timeOfDay.length > 0 && styleB && styleB.timeOfDay && styleB.timeOfDay.length > 0) {
        const intersect = styleA.timeOfDay.filter(x => styleB.timeOfDay.includes(x)).length;
        const union = styleA.timeOfDay.length + styleB.timeOfDay.length - intersect;
        const score = union > 0 ? (intersect / union) : 0.0;
        scores.push(score);
    }

    // 4. Interests (Always evaluated if at least one has it)
    const intA = Array.isArray(userA.interests) ? userA.interests : [];
    const intB = Array.isArray(userB.interests) ? userB.interests : [];
    if (intA.length > 0 || intB.length > 0) {
        const intersect = intA.filter(x => intB.includes(x)).length;
        const union = intA.length + intB.length - intersect;
        const score = union > 0 ? (intersect / union) : 0.0;
        scores.push(score);
    }

    if (scores.length === 0) return 50; // Fallback if no matching fields are found

    const finalScore = scores.reduce((sum, s) => sum + s, 0) / scores.length;
    return Math.round(finalScore * 100);
};

// Helper to map trip budget in THB to a 1-10 score equivalent
const mapTripBudgetToRating = (budgetVal) => {
    const val = Number(budgetVal) || 0;
    if (val <= 1000) return 2;
    if (val <= 2000) return 4;
    if (val <= 4000) return 6;
    if (val <= 7000) return 8;
    return 10;
};

// Helper to calculate exact user-to-trip compatibility percentage
export const calculateTripCompatibility = (user, trip) => {
    const styleU = normalizeTravelStyle(user.travelStyle);

    let scores = [];

    // 1. Budget Rating
    // We use the new budgetRating from the trip, fallback to mapped THB budget if not set
    const tripBudgetRating = trip.budgetRating != null ? trip.budgetRating : mapTripBudgetToRating(trip.budget);
    if (styleU && styleU.budget !== null) {
        const score = 1.0 - (Math.abs(styleU.budget - tripBudgetRating) / 9.0);
        scores.push(score);
    }

    // 2. Activity Style
    // We use the new activityStyle from the trip, fallback to creator's style if not set
    const styleC = normalizeTravelStyle(trip.creator && trip.creator.travelStyle ? trip.creator.travelStyle : null);
    const tripPace = trip.activityStyle != null ? trip.activityStyle : (styleC ? styleC.activityStyle : null);
    if (styleU && styleU.activityStyle !== null && tripPace !== null) {
        const score = 1.0 - (Math.abs(styleU.activityStyle - tripPace) / 9.0);
        scores.push(score);
    }

    // 3. Time of Day
    // We use timeOfDay from trip, fallback to creator's time if not set
    const tripTime = (trip.timeOfDay && trip.timeOfDay.length > 0) ? trip.timeOfDay : (styleC ? styleC.timeOfDay : []);
    if (styleU && styleU.timeOfDay && styleU.timeOfDay.length > 0 && tripTime && tripTime.length > 0) {
        const intersect = styleU.timeOfDay.filter(x => tripTime.includes(x)).length;
        const union = styleU.timeOfDay.length + tripTime.length - intersect;
        const score = union > 0 ? (intersect / union) : 0.0;
        scores.push(score);
    }

    // 4. Category
    const userInterests = Array.isArray(user.interests) ? user.interests : [];
    if (trip.category) {
        if (userInterests.includes(trip.category)) {
            scores.push(1.0);
        } else if (userInterests.length > 0) {
            scores.push(0.0);
        }
    }

    if (scores.length === 0) return 50;

    const finalScore = scores.reduce((sum, s) => sum + s, 0) / scores.length;
    return Math.round(finalScore * 100);
};

// Match Buddies (Find similar users)
export const findBuddy = async (req, res) => {
    try {
        const userId = req.user.userId;

        // 1. Get Current User
        const currentUser = await prisma.user.findUnique({
            where: { id: userId },
            select: { id: true, interests: true, travelStyle: true }
        });

        if (!currentUser) {
            return res.status(404).json({ error: 'User not found' });
        }

        // 2. Get users already swiped (liked)
        const swipedMatches = await prisma.userMatch.findMany({
            where: { likerId: userId, status: 'like' },
            select: { likedId: true }
        });
        const swipedIds = swipedMatches.map(m => m.likedId);

        // 3. Get All Other Users (Exclude self and swiped)
        const users = await prisma.user.findMany({
            where: {
                id: {
                    notIn: [userId, ...swipedIds]
                }
            },
            select: {
                id: true,
                name: true,
                email: true,
                role: true,
                profileImage: true,
                interests: true,
                bio: true,
                gender: true,
                age: true,
                travelStyle: true
            }
        });

        // 4. Calculate Similarity using exact 4-step logic
        const matches = users.map(user => {
            const similarityScore = calculateDetailedCompatibility(currentUser, user);
            return {
                ...user,
                matchScore: similarityScore
            };
        })
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
            select: { id: true, interests: true, travelStyle: true }
        });

        if (!currentUser) {
            return res.status(404).json({ error: 'User not found' });
        }

        // 2. Get Active Trips
        const trips = await prisma.trip.findMany({
            where: {
                endDate: { gte: new Date() } // Only future/ongoing trips
            },
            include: {
                creator: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        role: true,
                        profileImage: true,
                        interests: true,
                        travelStyle: true
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

        // 3. Calculate compatibility using exact 4-step logic
        const matches = trips.map(trip => {
            const score = calculateTripCompatibility(currentUser, trip);
            return {
                ...trip,
                matchScore: score
            };
        })
            .sort((a, b) => b.matchScore - a.matchScore)
            .slice(0, 20);

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
                
                // Fetch users for notification
                const targetUser = await prisma.user.findUnique({ where: { id: targetId } });
                const currentUser = await prisma.user.findUnique({ where: { id: userId } });
                
                if (targetUser && currentUser) {
                    await prisma.notification.create({
                        data: {
                            userId: targetId,
                            title: "It's a Match! 🎉",
                            message: `คุณและ ${currentUser.name} ใจตรงกัน! เริ่มทักทายกันได้เลย`,
                            type: "match",
                            relatedId: userId
                        }
                    });
                }
            } else {
                // DEV MODE FIX: Auto-create the opposite like so the user can test matching alone!
                console.log(`[DEV MODE] Auto-generating opposite like from ${targetId} to ${userId} so it becomes a mutual match!`);
                
                // We create the opposite like first
                await prisma.userMatch.upsert({
                    where: {
                        likerId_likedId: {
                            likerId: targetId,
                            likedId: userId
                        }
                    },
                    update: { status: 'like', isMutual: true },
                    create: {
                        likerId: targetId,
                        likedId: userId,
                        status: 'like',
                        isMutual: true
                    }
                });
                
                isMutual = true; // Set this one to true as well!
                
                // Notification for dev mode
                const targetUser = await prisma.user.findUnique({ where: { id: targetId } });
                const currentUser = await prisma.user.findUnique({ where: { id: userId } });
                if (targetUser && currentUser) {
                    await prisma.notification.create({
                        data: {
                            userId: targetId, // Target user gets notification
                            title: "It's a Match! 🎉",
                            message: `คุณและ ${currentUser.name} ใจตรงกัน! เริ่มทักทายกันได้เลย`,
                            type: "match",
                            relatedId: userId
                        }
                    });
                    
                    // Also notify the current user in dev mode so they can see it locally immediately!
                    await prisma.notification.create({
                        data: {
                            userId: userId,
                            title: "It's a Match! 🎉 (Dev Auto-Match)",
                            message: `${targetUser.name} ปัดขวาตอบกลับคุณอัตโนมัติ (Dev Mode)!`,
                            type: "match",
                            relatedId: targetId
                        }
                    });
                }
            }
        }

        // Create or update match for current user
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
                role: true,
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
