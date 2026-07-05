
// Helper to calculate exact user-to-user compatibility percentage (based on the 4 questionnaire pillars)
const calculateDetailedCompatibility = (userA, userB) => {
    const hasStyleA = userA.travelStyle && typeof userA.travelStyle === 'object';
    const hasStyleB = userB.travelStyle && typeof userB.travelStyle === 'object';

    // 1. Budget Level (25%)
    let budgetScore = 0.5; // neutral fallback
    if (hasStyleA && hasStyleB) {
        const ratingA = Number(userA.travelStyle.budget);
        const ratingB = Number(userB.travelStyle.budget);
        if (!isNaN(ratingA) && !isNaN(ratingB)) {
            budgetScore = 1.0 - (Math.abs(ratingA - ratingB) / 9.0);
        }
    }

    // 2. Activity Style (25%)
    let activityScore = 0.5; // neutral fallback
    if (hasStyleA && hasStyleB) {
        const ratingA = Number(userA.travelStyle.activityStyle);
        const ratingB = Number(userB.travelStyle.activityStyle);
        if (!isNaN(ratingA) && !isNaN(ratingB)) {
            activityScore = 1.0 - (Math.abs(ratingA - ratingB) / 9.0);
        }
    }

    // 3. Time of Day (25%)
    let timeScore = 0.5; // neutral fallback
    const timeA = userA.travelStyle?.timeOfDay;
    const timeB = userB.travelStyle?.timeOfDay;
    const arrayA = Array.isArray(timeA) ? timeA : [];
    const arrayB = Array.isArray(timeB) ? timeB : [];
    if (arrayA.length > 0 || arrayB.length > 0) {
        const intersect = arrayA.filter(x => arrayB.includes(x)).length;
        const union = new Set([...arrayA, ...arrayB]).size;
        timeScore = union > 0 ? (intersect / union) : 1.0;
    }

    // 4. Interests (25%)
    let interestScore = 0.5; // neutral fallback
    const intA = Array.isArray(userA.interests) ? userA.interests : [];
    const intB = Array.isArray(userB.interests) ? userB.interests : [];
    if (intA.length > 0 || intB.length > 0) {
        const intersect = intA.filter(x => intB.includes(x)).length;
        const union = new Set([...intA, ...intB]).size;
        interestScore = union > 0 ? (intersect / union) : 1.0;
    }

    // Weighted average
    const finalScore = (budgetScore * 0.25) + (activityScore * 0.25) + (timeScore * 0.25) + (interestScore * 0.25);
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
const calculateTripCompatibility = (user, trip) => {
    // 1. Budget (25%) - User budget rating vs Trip mapped budget rating
    let budgetScore = 0.5;
    const userBudget = user.travelStyle?.budget;
    if (userBudget !== undefined) {
        const userRating = Number(userBudget) || 5;
        const tripRating = mapTripBudgetToRating(trip.budget);
        budgetScore = 1.0 - (Math.abs(userRating - tripRating) / 9.0);
    }

    // 2. Activity Style (25%) - User vs Creator
    let activityScore = 0.5;
    const userActivity = user.travelStyle?.activityStyle;
    const creatorActivity = trip.creator?.travelStyle?.activityStyle;
    if (userActivity !== undefined && creatorActivity !== undefined) {
        const ratingU = Number(userActivity) || 5;
        const ratingC = Number(creatorActivity) || 5;
        activityScore = 1.0 - (Math.abs(ratingU - ratingC) / 9.0);
    }

    // 3. Time of Day (25%) - User vs Creator
    let timeScore = 0.5;
    const userTime = user.travelStyle?.timeOfDay;
    const creatorTime = trip.creator?.travelStyle?.timeOfDay;
    const arrayU = Array.isArray(userTime) ? userTime : [];
    const arrayC = Array.isArray(creatorTime) ? creatorTime : [];
    if (arrayU.length > 0 || arrayC.length > 0) {
        const intersect = arrayU.filter(x => arrayC.includes(x)).length;
        const union = new Set([...arrayU, ...arrayC]).size;
        timeScore = union > 0 ? (intersect / union) : 1.0;
    }

    // 4. Category Match (25%) - User interests vs Trip category
    let categoryScore = 0.0;
    const userInterests = Array.isArray(user.interests) ? user.interests : [];
    if (trip.category && userInterests.includes(trip.category)) {
        categoryScore = 1.0;
    } else if (userInterests.length === 0) {
        categoryScore = 0.5; // neutral
    }

    const finalScore = (budgetScore * 0.25) + (activityScore * 0.25) + (timeScore * 0.25) + (categoryScore * 0.25);
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

        // 2. Get users already swiped (liked or disliked)
        const swipedMatches = await prisma.userMatch.findMany({
            where: { likerId: userId },
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
