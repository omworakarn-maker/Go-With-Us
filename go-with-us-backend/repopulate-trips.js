import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function repopulate() {
    try {
        console.log('🏁 Starting repopulation...');

        const admin = await prisma.user.findUnique({
            where: { email: 'admin@gowithus.com' },
        });

        const user = await prisma.user.findUnique({
            where: { email: 'user@gowithus.com' },
        });

        if (!admin || !user) {
            console.error('❌ Admin or User not found. Please run seed first.');
            return;
        }

        const trips = [
            {
                title: 'ทริปไหว้พระอยุธยา',
                destination: 'อยุธยา',
                description: 'ไปไหว้พระ 9 วัด รอบเกาะเมืองอยุธยา พร้อมทานกุ้งแม่น้ำเผาช่วงเย็น',
                startDate: new Date('2026-03-10'),
                endDate: new Date('2026-03-10'),
                budget: 1500,
                maxParticipants: 5,
                category: 'กินเที่ยว',
                creatorId: user.id,
            },
            {
                title: 'เดินป่าดอยม่อนจอง',
                destination: 'เชียงใหม่',
                description: 'ทริปเดินป่าชมเขาสิงโตม่อนจอง พักแรม 1 คืน เน้นคนชอบธรรมชาติ',
                startDate: new Date('2026-04-05'),
                endDate: new Date('2026-04-07'),
                budget: 3500,
                maxParticipants: 8,
                category: 'ธรรมชาติ',
                creatorId: user.id,
            },
            {
                title: 'ปาร์ตี้ริมหาดพัทยา',
                destination: 'พัทยา',
                description: 'วันหยุดยาวไปชิลริมหาดพัทยา ฟังดนตรีสด ทานอาหารทะเลกันครับ',
                startDate: new Date('2026-02-25'),
                endDate: new Date('2026-02-27'),
                budget: 4500,
                maxParticipants: 4,
                category: 'ปาร์ตี้',
                creatorId: admin.id,
            },
            {
                title: 'Road Trip น่าน 3 วัน 2 คืน',
                destination: 'น่าน',
                description: 'ขับรถเที่ยวถนนหมายเลข 3 พักโฮมสเตย์ที่ดอยสกาด บรรยากาศเงียบสงบ',
                startDate: new Date('2026-05-15'),
                endDate: new Date('2026-05-18'),
                budget: 6000,
                maxParticipants: 4,
                category: 'กินเที่ยว',
                creatorId: user.id,
            },
        ];

        console.log('⏳ Creating trips...');
        for (const trip of trips) {
            await prisma.trip.create({
                data: trip,
            });
            console.log(`✅ Created trip: ${trip.title}`);
        }

        console.log('\n🎉 Repopulation complete!');
    } catch (error) {
        console.error('❌ Error during repopulation:', error);
    } finally {
        await prisma.$disconnect();
    }
}

repopulate();
