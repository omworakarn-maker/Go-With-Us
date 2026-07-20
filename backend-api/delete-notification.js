import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function deleteNotifications() {
    const args = process.argv.slice(2);

    if (args.length < 1) {
        console.log('\n❌ Error: Missing arguments');
        console.log('Usage:');
        console.log('  1. Delete by ID:   npm run del-noti <id>');
        console.log('  2. Delete ALL:     npm run del-noti all');
        console.log('  3. Delete by Type: npm run del-noti type <alert|trip|system>\n');
        process.exit(1);
    }

    const command = args[0].toLowerCase();

    try {
        if (command === 'all') {
            const confirm = await askConfirmation('⚠️ Are you sure you want to delete ALL notifications? (y/n): ');
            if (!confirm) return;

            const result = await prisma.notification.deleteMany({});
            console.log(`\n✅ Deleted all notifications (${result.count} items).`);
        }
        else if (command === 'type') {
            const type = args[1];
            if (!type) {
                console.log('❌ Error: Please specify type (alert, trip, system)');
                return;
            }
            const result = await prisma.notification.deleteMany({ where: { type } });
            console.log(`\n✅ Deleted all notifications of type "${type}" (${result.count} items).`);
        }
        else {
            // Assume ID
            const id = args[0];
            const deleted = await prisma.notification.delete({ where: { id } });
            console.log(`\n✅ Notification with ID "${id}" deleted.`);
            console.log(`📌 Title: ${deleted.title}`);
        }
    } catch (error) {
        if (error.code === 'P2025') {
            console.error('\n❌ Error: Notification not found.');
        } else {
            console.error('\n❌ Failed to delete:', error.message);
        }
    } finally {
        await prisma.$disconnect();
    }
}

async function askConfirmation(query) {
    const readline = (await import('readline')).createInterface({
        input: process.stdin,
        output: process.stdout,
    });
    return new Promise(resolve => readline.question(query, ans => {
        readline.close();
        resolve(ans.toLowerCase() === 'y');
    }));
}

deleteNotifications();
