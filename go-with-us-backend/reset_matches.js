import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log("Resetting all swipe/match history...");
    
    // Delete all records in UserMatch
    const result = await prisma.userMatch.deleteMany({});
    
    // Delete all private messages
    const msgResult = await prisma.message.deleteMany({
        where: { tripId: null }
    });
    
    console.log(`Deleted ${result.count} match records and ${msgResult.count} private messages. History is now completely reset!`);
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
