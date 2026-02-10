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

        const notification = await prisma.notification.create({
            data: {
                title,
                message: message || '',
                type,
                userId: userId || null, // null for all users
            },
        });

        console.log('\n✅ Notification Sent Successfully!');
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        console.log(`🆔 ID:      ${notification.id}`);
        console.log(`📌 Title:   ${notification.title}`);
        console.log(`📝 Message: ${notification.message || '(No message)'}`);
        console.log(`🏷️  Type:    ${notification.type}`);
        console.log(`👤 Target:  ${notification.userId ? `User ${notification.userId}` : 'All Users'}`);
        console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

    } catch (error) {
        console.error('\n❌ Failed to send notification:', error.message);
    } finally {
        await prisma.$disconnect();
    }
}

sendNotification();
