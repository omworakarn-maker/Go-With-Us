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
        
        // Map large THB values to 1-10 rating scale to fix massive vector magnitudes
        if (budget > 10) {
            if (budget <= 500) budget = 2;
            else if (budget <= 1000) budget = 4;
            else if (budget <= 2000) budget = 6;
            else if (budget <= 5000) budget = 8;
            else budget = 10;
        }
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

const MATCH_WEIGHTS = {
    category: 0.35,
    budget: 0.30,
    activityStyle: 0.20,
    timeOfDay: 0.15
};

const MATCH_CATEGORIES = ['ทะเล', 'ภูเขา', 'แคมป์ปิ้ง', 'เที่ยวเมือง', 'คาเฟ่', 'อาหาร', 'แฮงเอาต์', 'ถ่ายรูป', 'ช้อปปิ้ง', 'คอนเสิร์ต', 'ผจญภัย', 'ไหว้พระ', 'อื่นๆ'];
const MATCH_TIMES = ['morning', 'noon', 'evening', 'night'];

const clamp = (value, min, max) => Math.min(max, Math.max(min, value));

// Encode a continuous value as a unit vector on a quarter circle. Unlike a
// single scalar, this lets Cosine Similarity measure how far two values differ.
const encodeContinuous = (value, min, max) => {
    const position = clamp((Number(value) - min) / (max - min), 0, 1);
    const angle = position * (Math.PI / 2);
    return [Math.cos(angle), Math.sin(angle)];
};

// Budget uses a logarithmic position because a difference of 500 baht matters
// more around 500–1,000 than around 10,000–15,000 baht.
const encodeBudget = (budgetTHB) => {
    const minBudget = 100;
    const maxBudget = 50000;
    const safeBudget = clamp(Number(budgetTHB) || minBudget, minBudget, maxBudget);
    const position = Math.log(safeBudget / minBudget) / Math.log(maxBudget / minBudget);
    const angle = position * (Math.PI / 2);
    return [Math.cos(angle), Math.sin(angle)];
};

const encodeMultiHotUnit = (selected, universe) => {
    const selectedSet = new Set(Array.isArray(selected) ? selected : []);
    const raw = universe.map(value => selectedSet.has(value) ? 1 : 0);
    const norm = Math.sqrt(raw.reduce((sum, value) => sum + (value * value), 0));
    return norm > 0 ? raw.map(value => value / norm) : raw;
};

const appendWeightedBlock = (target, block, weight) => {
    const scale = Math.sqrt(weight);
    target.push(...block.map(value => value * scale));
};

const blockCosinePercentage = (userBlock, tripBlock) => (
    Math.round(clamp(cosineSimilarity(userBlock, tripBlock), 0, 1) * 100)
);



const calculateDetailedCompatibility = (userA, userB) => {
    const styleA = normalizeTravelStyle(userA.travelStyle);
    const styleB = normalizeTravelStyle(userB.travelStyle);

    let totalScore = 0;
    let totalWeight = 0;

    // 1. Budget (Weight = 3)
    if (styleA && styleA.budget !== null && styleB && styleB.budget !== null) {
        const diff = Math.abs(styleA.budget - styleB.budget);
        // rating is 1-10. Max diff is 9.
        let score = 1.0;
        if (diff > 1) {
            score = Math.max(0, 1.0 - ((diff - 1) / 8.0));
        }
        totalScore += score * 3;
        totalWeight += 3;
    } else {
        // If either doesn't have budget, give average score but lower weight
        totalScore += 0.5 * 1;
        totalWeight += 1;
    }

    // 2. Activity Style (Weight = 2)
    if (styleA && styleA.activityStyle !== null && styleB && styleB.activityStyle !== null) {
        const diff = Math.abs(styleA.activityStyle - styleB.activityStyle);
        let score = 1.0;
        if (diff > 1) {
            score = Math.max(0, 1.0 - ((diff - 1) / 8.0));
        }
        totalScore += score * 2;
        totalWeight += 2;
    } else {
        totalScore += 0.5 * 1;
        totalWeight += 1;
    }

    // 3. Time of Day (Weight = 1)
    if (styleA && styleA.timeOfDay && styleA.timeOfDay.length > 0 && 
        styleB && styleB.timeOfDay && styleB.timeOfDay.length > 0) {
        const intersect = styleA.timeOfDay.filter(x => styleB.timeOfDay.includes(x)).length;
        const union = new Set([...styleA.timeOfDay, ...styleB.timeOfDay]).size;
        const score = union > 0 ? (intersect / union) : 0.0;
        
        // Bonus for having overlapping times
        totalScore += score * 1.5;
        totalWeight += 1.5;
    } else {
        totalScore += 0.5 * 0.5;
        totalWeight += 0.5;
    }

    // 4. Interests (Weight = 2)
    const intA = Array.isArray(userA.interests) ? userA.interests : [];
    const intB = Array.isArray(userB.interests) ? userB.interests : [];
    
    if (intA.length > 0 && intB.length > 0) {
        const intersect = intA.filter(x => intB.includes(x)).length;
        // Dice coefficient for better matching on interests
        const score = (2.0 * intersect) / (intA.length + intB.length);
        totalScore += score * 2;
        totalWeight += 2;
    } else {
        totalScore += 0.5 * 1;
        totalWeight += 1;
    }

    let percentage = 0;
    if (totalWeight > 0) {
        percentage = (totalScore / totalWeight) * 100.0;
    }
    
    if (percentage > 100) percentage = 100;
    if (percentage < 0) percentage = 0;
    
    return Math.round(percentage);
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
    const breakdown = {
        budget: null,
        activityStyle: null,
        category: null,
        timeOfDay: null,
        groupMatch: null
    };

    // A full or already-ended trip is not joinable, regardless of preference.
    const goingCount = Array.isArray(trip.participants)
        ? trip.participants.filter(participant => !participant.status || participant.status === 'going').length
        : 0;
    if (trip.maxParticipants && goingCount >= Number(trip.maxParticipants)) {
        breakdown.groupMatch = 0;
        return { total: 0, breakdown, tripMatch: 0, cosineSimilarity: 0 };
    }

    const lastTripDate = trip.endDate || trip.startDate;
    if (lastTripDate) {
        const tripDay = new Date(lastTripDate);
        const today = new Date();
        tripDay.setHours(23, 59, 59, 999);
        if (tripDay < today) {
            return { total: 0, breakdown, tripMatch: 0, cosineSimilarity: 0 };
        }
    }

    const userVector = [];
    const tripVector = [];

    // 1. Budget vector (30%)
    const rawUserBudget = user.travelStyle && Number(user.travelStyle.budget);
    const userBudgetTHB = styleU && styleU.budget !== null
        ? (Number.isFinite(rawUserBudget) && rawUserBudget > 10
            ? rawUserBudget
            : mapRatingToBudget(styleU.budget))
        : null;
    const tripBudgetTHB = trip.budget !== undefined && trip.budget !== null
        ? Number(trip.budget)
        : null;
    if (userBudgetTHB !== null && Number.isFinite(tripBudgetTHB)) {
        const userBudgetBlock = encodeBudget(userBudgetTHB);
        const tripBudgetBlock = tripBudgetTHB === 0
            ? userBudgetBlock
            : encodeBudget(tripBudgetTHB);
        appendWeightedBlock(userVector, userBudgetBlock, MATCH_WEIGHTS.budget);
        appendWeightedBlock(tripVector, tripBudgetBlock, MATCH_WEIGHTS.budget);
        breakdown.budget = tripBudgetTHB === 0
            ? 100
            : blockCosinePercentage(userBudgetBlock, tripBudgetBlock);
    }

    // 2. Activity-style vector (20%)
    const tripPace = trip.activityStyle != null ? trip.activityStyle : (styleC ? styleC.activityStyle : null);
    if (styleU && styleU.activityStyle !== null && tripPace !== null) {
        const userActivityBlock = encodeContinuous(styleU.activityStyle, 1, 10);
        const tripActivityBlock = encodeContinuous(tripPace, 1, 10);
        appendWeightedBlock(userVector, userActivityBlock, MATCH_WEIGHTS.activityStyle);
        appendWeightedBlock(tripVector, tripActivityBlock, MATCH_WEIGHTS.activityStyle);
        breakdown.activityStyle = blockCosinePercentage(userActivityBlock, tripActivityBlock);
    }

    // 3. Time-of-day vector (15%)
    const tripTime = (trip.timeOfDay && trip.timeOfDay.length > 0) ? trip.timeOfDay : (styleC ? styleC.timeOfDay : []);
    if (styleU && styleU.timeOfDay && styleU.timeOfDay.length > 0 && tripTime && tripTime.length > 0) {
        const userTimeBlock = encodeMultiHotUnit(styleU.timeOfDay, MATCH_TIMES);
        const tripTimeBlock = encodeMultiHotUnit(tripTime, MATCH_TIMES);
        if (userTimeBlock.some(Boolean) && tripTimeBlock.some(Boolean)) {
            appendWeightedBlock(userVector, userTimeBlock, MATCH_WEIGHTS.timeOfDay);
            appendWeightedBlock(tripVector, tripTimeBlock, MATCH_WEIGHTS.timeOfDay);
            breakdown.timeOfDay = blockCosinePercentage(userTimeBlock, tripTimeBlock);
        }
    }

    // 4. Interest/category vector (35%)
    const userInterests = Array.isArray(user.interests) ? user.interests : [];
    if (trip.category && userInterests.length > 0) {
        const userCategoryBlock = encodeMultiHotUnit(userInterests, MATCH_CATEGORIES);
        const tripCategoryBlock = encodeMultiHotUnit([trip.category], MATCH_CATEGORIES);
        if (userCategoryBlock.some(Boolean) && tripCategoryBlock.some(Boolean)) {
            appendWeightedBlock(userVector, userCategoryBlock, MATCH_WEIGHTS.category);
            appendWeightedBlock(tripVector, tripCategoryBlock, MATCH_WEIGHTS.category);
            breakdown.category = blockCosinePercentage(userCategoryBlock, tripCategoryBlock);
        }
    }

    // Main algorithm: Cosine Similarity between the weighted User and Trip vectors.
    const similarity = clamp(cosineSimilarity(userVector, tripVector), 0, 1);
    let percentage = similarity * 100;
    
    // Feasibility is a post-processing rule, not a replacement for Cosine.
    if (userBudgetTHB !== null && tripBudgetTHB > userBudgetTHB * 2) {
        percentage = Math.min(percentage, 39);
    }
    
    const tripTotal = Math.round(percentage);

    return {
        total: tripTotal,
        breakdown,
        tripMatch: tripTotal,
        cosineSimilarity: Number(similarity.toFixed(4))
    };
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
