import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log("Updating existing likes to mutual matches...");
    
    // Update all existing likes to be mutual
    const result = await prisma.userMatch.updateMany({
        where: {
            status: 'like',
            isMutual: false
        },
        data: {
            isMutual: true
        }
    });
    
    console.log(`Updated ${result.count} matches to mutual.`);

    // Find all likes to create the reverse match
    const allLikes = await prisma.userMatch.findMany({
        where: { status: 'like' }
    });

    let reverseCount = 0;
    for (const match of allLikes) {
        // Upsert the reverse match
        await prisma.userMatch.upsert({
            where: {
                likerId_likedId: {
                    likerId: match.likedId,
                    likedId: match.likerId
                }
            },
            update: { isMutual: true },
            create: {
                likerId: match.likedId,
                likedId: match.likerId,
                status: 'like',
                isMutual: true
            }
        });
        reverseCount++;
    }

    console.log(`Processed ${reverseCount} reverse matches.`);
}

main()
    .catch(e => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
