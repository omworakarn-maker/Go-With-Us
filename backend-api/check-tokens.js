import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function checkTokens() {
    try {
        const usersCount = await prisma.user.count();
        const usersWithToken = await prisma.user.count({
            where: {
                fcmToken: { not: null }
            }
        });

        console.log(`\n📊 User Stats:`);
        console.log(`   Total Users: ${usersCount}`);
        console.log(`   Users with FCM Token: ${usersWithToken}`);

        if (usersWithToken > 0) {
            const users = await prisma.user.findMany({
                where: { fcmToken: { not: null } },
                select: { id: true, name: true, fcmToken: true }
            });
            console.log('\nusers with tokens:');
            users.forEach(u => {
                console.log(`   - ${u.name} (${u.id}): ${u.fcmToken.substring(0, 15)}...`);
            });
        } else {
            console.log('\n❌ No users have an FCM token registered yet.');
            console.log('   Possible reasons:');
            console.log('   1. App didn\'t ask for permission.');
            console.log('   2. Simulator used (Simulators often fail to get native APNs tokens).');
            console.log('   3. "GoogleService-Info.plist" missing in iOS project.');
            console.log('   4. "Push Notifications" capability not enabled in Xcode.');
        }

    } catch (error) {
        console.error('Error:', error);
    } finally {
        await prisma.$disconnect();
    }
}

checkTokens();
