import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({ take: 1 });
  if (users.length === 0) return console.log("No users found");
  const creatorId = users[0].id;

  const trip = await prisma.trip.create({
    data: {
      title: "Test Trip with Style",
      destination: "BKK",
      startDate: new Date(),
      budget: 1000,
      maxParticipants: 10,
      category: "เมือง",
      activityStyle: 9,
      timeOfDay: ["morning", "night"],
      creatorId: creatorId
    }
  });
  console.log("Created:", trip);
}
main().catch(console.error).finally(() => prisma.$disconnect());
