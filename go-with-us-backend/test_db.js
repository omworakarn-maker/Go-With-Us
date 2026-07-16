import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function run() {
    const trip = await prisma.trip.findFirst({ where: { budget: 5000 }, select: { id: true, title: true, budget: true } });
    console.log("Trip:", trip);
    const users = await prisma.user.findMany({ select: { id: true, name: true, travelStyle: true } });
    console.log("Users:", users.map(u => ({ name: u.name, budget: u.travelStyle?.budget })));
}
run();
