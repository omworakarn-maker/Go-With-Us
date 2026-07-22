import prisma from '../utils/prismaClient.js';
import { sendPushNotification } from '../utils/firebase.js';
import { cosineSimilarity } from '../utils/ai.js';


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

// Helper to build a numerical Feature Vector for Cosine Similarity
const buildFeatureVector = (travelStyle, interests, isTrip = false, tripCategory = null) => {
    const style = normalizeTravelStyle(travelStyle);
    const vector = [];
    
    // 1. Budget (0 to 1) - Default to 0.5 if missing
    vector.push((style && style.budget !== null) ? style.budget / 10.0 : 0.5);
    
    // 2. Activity Style (0 to 1) - Default to 0.5 if missing
    vector.push((style && style.activityStyle !== null) ? style.activityStyle / 10.0 : 0.5);
    
    // 3. Interests / Categories (12 Dimensions)
    const allCategories = ['ทะเล', 'ภูเขา', 'แคมป์ปิ้ง', 'เที่ยวเมือง', 'คาเฟ่', 'อาหาร', 'แฮงเอาต์', 'ถ่ายรูป', 'ช้อปปิ้ง', 'คอนเสิร์ต', 'ผจญภัย', 'ไหว้พระ'];
    const userInts = Array.isArray(interests) ? interests : [];
    
    for (const cat of allCategories) {
        if (isTrip) {
            // For trips, they usually have one main category
            vector.push(tripCategory === cat ? 1.0 : 0.0);
        } else {
            vector.push(userInts.includes(cat) ? 1.0 : 0.0);
        }
    }
    
    // 4. Time of Day (4 Dimensions)
    const allTimes = ['morning', 'noon', 'evening', 'night'];
    const times = (style && Array.isArray(style.timeOfDay)) ? style.timeOfDay : [];
    
    for (const t of allTimes) {
        vector.push(times.includes(t) ? 1.0 : 0.0);
    }
    
    return vector;
};



// Helper to calculate user-to-user compatibility percentage using Cosine Similarity
const calculateDetailedCompatibility = (userA, userB) => {
    const vecA = buildFeatureVector(userA.travelStyle, userA.interests, false);
    const vecB = buildFeatureVector(userB.travelStyle, userB.interests, false);
    
    const simScore = cosineSimilarity(vecA, vecB);
    
    // Convert Cosine Similarity (0 to 1) to percentage (0 to 100)
    // Vectors are mostly positive (0 or 1), so score is naturally between 0 and 1.
    // If they match perfectly, it's 1.0 (100%)
    return Math.round(simScore * 100);
};

// Helper to map rating (1-10) to THB
const mapRatingToBudget = (rating) => {
    if (rating === 0 || rating === "0") return 0;
    const r = Number(rating) || 5;
    if (r > 10) return r; // Already in THB
    if (r <= 2) return 500;
    if (r <= 4) return 1000;
    if (r <= 6) return 2000;
    if (r <= 8) return 5000;
    return 8000;
};

// Helper to map THB to rating (1-10)
const mapBudgetToRating = (thb) => {
    if (!thb) return 5;
    if (thb <= 500) return 2;
    if (thb <= 1000) return 4;
    if (thb <= 2000) return 6;
    if (thb <= 5000) return 8;
    return 10;
};

// Helper to calculate exact user-to-trip compatibility percentage
export const calculateTripCompatibility = (user, trip) => {
    const result = calculateTripCompatibilityDetailed(user, trip);
    return result.total;
};

// Detailed version that returns per-factor scores for UI breakdown
export const calculateTripCompatibilityDetailed = (user, trip) => {
    const styleU = normalizeTravelStyle(user.travelStyle);
    const styleC = normalizeTravelStyle(trip.creator && trip.creator.travelStyle ? trip.creator.travelStyle : null);

    let totalScore = 0;
    let totalWeight = 0;
    const breakdown = {
        budget: null,
        activityStyle: null,
        category: null,
        timeOfDay: null,
        groupMatch: null
    };

    // 1. Budget — calculate from THB (Weight = 3)
    if (styleU && styleU.budget !== null) {
        const userBudgetTHB = mapRatingToBudget(styleU.budget);
        const tripBudgetTHB = (trip.budget !== undefined && trip.budget !== null) ? Number(trip.budget) : 1000;
        
        let score = 1.0;
        
        if (tripBudgetTHB === 0) {
            score = 1.0; // 100% match if trip is Free (0 THB)
        } else {
            const diffTHB = Math.abs(userBudgetTHB - tripBudgetTHB);
            // Use percentage difference instead of absolute THB
            const diffPercent = diffTHB / Math.max(userBudgetTHB, 100);
            
            // Accept up to 30% difference without penalty
            if (diffPercent > 0.3) {
                // Drop score to 0 linearly as difference approaches 100%
                score = Math.max(0.0, 1.0 - ((diffPercent - 0.3) / 0.7));
            }
        }
        
        totalScore += score * 3;
        totalWeight += 3;
        breakdown.budget = Math.round(score * 100);
    }

    // 2. Activity Style (With Flexibility +/- 2) (Weight = 1)
    const tripPace = trip.activityStyle != null ? trip.activityStyle : (styleC ? styleC.activityStyle : null);
    if (styleU && styleU.activityStyle !== null && tripPace !== null) {
        const diff = Math.abs(styleU.activityStyle - tripPace);
        let score = 1.0;
        if (diff > 2) {
            score = 1.0 - ((diff - 2) / 7.0);
        }
        totalScore += score;
        totalWeight += 1;
        breakdown.activityStyle = Math.round(score * 100);
    }

    // 3. Time of Day (Weight = 1)
    const tripTime = (trip.timeOfDay && trip.timeOfDay.length > 0) ? trip.timeOfDay : (styleC ? styleC.timeOfDay : []);
    if (styleU && styleU.timeOfDay && styleU.timeOfDay.length > 0 && tripTime && tripTime.length > 0) {
        const intersect = styleU.timeOfDay.filter(x => tripTime.includes(x)).length;
        const minLen = Math.min(styleU.timeOfDay.length, tripTime.length);
        const score = minLen > 0 ? (intersect / minLen) : 0.0;
        totalScore += score;
        totalWeight += 1;
        breakdown.timeOfDay = Math.round(score * 100);
    }

    // 4. Category (Weight = 1)
    const userInterests = Array.isArray(user.interests) ? user.interests : [];
    if (trip.category) {
        if (userInterests.includes(trip.category)) {
            breakdown.category = 100;
        } else {
            breakdown.category = 0;
        }
    }

    // Replace the old weighted average calculation with Feature Vector Cosine Similarity
    const userVector = buildFeatureVector(user.travelStyle, user.interests, false);
    
    // For the trip, we build the vector using the trip's creator style (or trip style) and the trip's main category
    const tripVector = buildFeatureVector(
        trip.creator ? trip.creator.travelStyle : null, 
        [], // trips don't have an interests array, they have a single category
        true, 
        trip.category
    );
    
    // Override specific trip attributes if they exist on the trip level (like budget and pace)
    if (trip.budget !== undefined && trip.budget !== null) {
        tripVector[0] = mapBudgetToRating(Number(trip.budget)) / 10.0;
    }
    if (trip.activityStyle !== undefined && trip.activityStyle !== null) {
        tripVector[1] = trip.activityStyle / 10.0;
    }
    
    const simScore = cosineSimilarity(userVector, tripVector);
    const tripTotal = Math.round(simScore * 100);

    return { total: tripTotal, breakdown, tripMatch: tripTotal };
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
                gallery: true,
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
                    // Notify target user
                    await prisma.notification.create({
                        data: {
                            userId: targetId,
                            title: "It's a Match! 🎉",
                            message: `คุณและ ${currentUser.name} ใจตรงกัน! เริ่มทักทายกันได้เลย`,
                            type: "match",
                            relatedId: userId
                        }
                    });
                    
                    if (targetUser.fcmToken) {
                        await sendPushNotification(targetUser.fcmToken, "It's a Match! 🎉", `คุณและ ${currentUser.name} ใจตรงกัน! เริ่มทักทายกันได้เลย`, {
                            type: 'match',
                            targetId: userId
                        });
                    }

                    // Notify current user
                    await prisma.notification.create({
                        data: {
                            userId: userId,
                            title: "It's a Match! 🎉",
                            message: `คุณและ ${targetUser.name} ใจตรงกัน! เริ่มทักทายกันได้เลย`,
                            type: "match",
                            relatedId: targetId
                        }
                    });
                    
                    if (currentUser.fcmToken) {
                        await sendPushNotification(currentUser.fcmToken, "It's a Match! 🎉", `คุณและ ${targetUser.name} ใจตรงกัน! เริ่มทักทายกันได้เลย`, {
                            type: 'match',
                            targetId: targetId
                        });
                    }
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
                gallery: true,
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
