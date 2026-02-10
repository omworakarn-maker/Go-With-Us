import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function sendNotification() {
    const args = process.argv.slice(2);

    if (args.length < 1) {
        console.log('\n❌ Error: Missing arguments');
        console.log('Usage: node send-notification.js "<title>" "<message>" [type] [userId]');
        console.log('Example: node send-notification.js "System Update" "The system will be down for maintenance." alert\n');
        process.exit(1);
    }

    const [title, message, type = 'alert', userId = null] = args;

    try {
        console.log('⏳ Sending notification...');

        let count = 0;

        if (userId) {
            // Create for single user
            const notification = await prisma.notification.create({
                data: {
                    title,
                    message: message || '',
                    type,
                    userId: userId,
                },
            });
            console.log(`✅ Notification created for user: ${userId}`);
            console.log(`🆔 ID: ${notification.id}`);
            count = 1;
        } else {
            // Create for ALL users
            const users = await prisma.user.findMany({ select: { id: true } });
            console.log(`✨ Found ${users.length} users. Creating notifications...`);

            // Create in batches to avoid overwhelming DB connection
            for (const user of users) {
                await prisma.notification.create({
                    data: {
                        title,
                        message: message || '',
                        type,
                        userId: user.id,
                    },
                });
            }
            count = users.length;
            console.log(`✅ Created ${count} notification records.`);
        }

        // Send Push Notification (Disabled for Free Tier - using Polling)
        console.log('\n🚀 Notification queued for local polling.');
        console.log('   (App will pick this up automatically within 10 seconds)');

    } catch (error) {
        console.error('\n❌ Failed to create notification:', error.message);
    } finally {
        await prisma.$disconnect();
    }
}

sendNotification();
