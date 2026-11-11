const CORRUPTED_INTERESTS = new Map([
    ['‡∏ó‡∏∞‡πÄ‡∏•', 'ทะเล'],
    ['‡∏†‡∏π‡πÄ‡∏Ç‡∏≤', 'ภูเขา'],
    ['‡πÅ‡∏Ñ‡∏°‡∏õ‡πå‡∏õ‡∏¥‡πâ‡∏á', 'แคมป์ปิ้ง'],
    ['‡πÄ‡∏ó‡∏µ‡πà‡∏¢‡∏ß‡πÄ‡∏°‡∏∑‡∏≠‡∏á', 'เที่ยวเมือง'],
    ['‡∏Ñ‡∏≤‡πÄ‡∏ü‡πà', 'คาเฟ่'],
    ['‡∏≠‡∏≤‡∏´‡∏≤‡∏£', 'อาหาร'],
    ['‡πÅ‡∏Æ‡∏á‡πÄ‡∏≠‡∏≤‡∏ï‡πå', 'แฮงเอาต์'],
    ['‡∏ñ‡πà‡∏≤‡∏¢‡∏£‡∏π‡∏õ', 'ถ่ายรูป'],
    ['‡∏ä‡πâ‡∏≠‡∏õ‡∏õ‡∏¥‡πâ‡∏á', 'ช้อปปิ้ง'],
    ['‡∏Ñ‡∏≠‡∏ô‡πÄ‡∏™‡∏¥‡∏£‡πå‡∏ï', 'คอนเสิร์ต'],
    ['‡∏ú‡∏à‡∏ç‡∏†‡∏±‡∏¢', 'ผจญภัย'],
    ['‡πÑ‡∏´‡∏ß‡πâ‡∏û‡∏£‡∏∞', 'ไหว้พระ']
]);

const repairLabel = value => CORRUPTED_INTERESTS.get(value) || value;
const repairLabels = values => Array.isArray(values)
    ? [...new Set(values.map(repairLabel))]
    : values;

async function repairInterestEncoding(db) {
    let updated = 0;

    const users = await db.user.findMany({ select: { id: true, interests: true } });
    for (const user of users) {
        const interests = repairLabels(user.interests);
        if (JSON.stringify(interests) !== JSON.stringify(user.interests)) {
            await db.user.update({ where: { id: user.id }, data: { interests } });
            updated += 1;
        }
    }

    const trips = await db.trip.findMany({
        select: { id: true, category: true, interestTags: true }
    });
    for (const trip of trips) {
        const category = repairLabel(trip.category);
        const interestTags = repairLabels(trip.interestTags);
        if (category !== trip.category || JSON.stringify(interestTags) !== JSON.stringify(trip.interestTags)) {
            await db.trip.update({ where: { id: trip.id }, data: { category, interestTags } });
            updated += 1;
        }
    }

    const participants = await db.participant.findMany({
        select: { id: true, interests: true }
    });
    for (const participant of participants) {
        const interests = repairLabels(participant.interests);
        if (JSON.stringify(interests) !== JSON.stringify(participant.interests)) {
            await db.participant.update({ where: { id: participant.id }, data: { interests } });
            updated += 1;
        }
    }

    return updated;
}

async function main() {
    require('dotenv').config();
    const { PrismaClient } = require('@prisma/client');
    const url = process.env.DIRECT_DATABASE_URL || process.env.DATABASE_URL;
    if (!url) throw new Error('Database URL is not configured.');
    const db = new PrismaClient({ datasources: { db: { url } } });
    try {
        const count = await repairInterestEncoding(db);
        console.log(`Interest encoding repair complete (${count} records updated).`);
    } finally {
        await db.$disconnect();
    }
}

module.exports = { repairLabel, repairLabels, repairInterestEncoding };
if (require.main === module) main().catch(error => {
    console.error(error.message);
    process.exitCode = 1;
});
