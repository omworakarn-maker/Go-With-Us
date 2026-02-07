
/**
 * คำนวณ Cosine Similarity ระหว่าง 2 Vector
 * @param {number[]} vecA - Vector ของ User (ความชอบ)
 * @param {number[]} vecB - Vector ของ Trip (ลักษณะทริป)
 * @returns {number} ค่าความเหมือน (-1 ถึง 1)
 */
export const cosineSimilarity = (vecA, vecB) => {
    if (!vecA || !vecB || vecA.length !== vecB.length) return 0;

    let dotProduct = 0;
    let normA = 0;
    let normB = 0;

    for (let i = 0; i < vecA.length; i++) {
        dotProduct += vecA[i] * vecB[i];
        normA += vecA[i] * vecA[i];
        normB += vecB[i] * vecB[i];
    }

    if (normA === 0 || normB === 0) return 0;

    return dotProduct / (Math.sqrt(normA) * Math.sqrt(normB));
};

/**
 * จัดลำดับทริปแนะนำ โดยใช้น้ำหนักจากหลายปัจจัย
 * 1. AI Vector Similarity (60%)
 * 2. Category Match (20%) - ตรงหมวดที่ชอบไหม
 * 3. Recent (10%) - ทริปใหม่ไหม
 * 4. Popularity (10%) - คนจองเยอะไหม
 */
export const rankTripsForUser = (user, trips) => {
    // ถ้า User ไม่มี Vector ให้ใช้แบบสุ่มหรือเรียงตามเวลาไปก่อน
    if (!user.embedding) {
        return trips.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    }

    return trips.map(trip => {
        // 1. Calculate Similarity Score
        const simScore = cosineSimilarity(user.embedding, trip.embedding || []);

        // 2. Category Bonus
        const categoryBonus = user.interests.includes(trip.category) ? 0.2 : 0;

        // 3. Final Score
        const finalScore = (simScore * 0.7) + categoryBonus;

        return { ...trip, score: finalScore };
    })
        .sort((a, b) => b.score - a.score); // เรียงจากมากไปน้อย
};
