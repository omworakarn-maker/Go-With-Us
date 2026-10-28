// Seeds/cleans "tc34_ui_*" data used by the iOS Simulator UI tests. Usage: node test-results/tc34-seed.mjs seed|cleanup
import bcrypt from '../backend-api/node_modules/bcryptjs/index.js';
import prisma from '../backend-api/src/utils/prismaClient.js';
const day = 86400000, PASSWORD = 'tcpassword';
const op = process.argv[2];
const cleanup = async () => {
  await prisma.trip.deleteMany({ where: { creator: { email: { startsWith: 'tc34_' } } } });
  await prisma.pendingRegistration.deleteMany({ where: { email: { startsWith: 'tc34_' } } });
  await prisma.user.deleteMany({ where: { email: { startsWith: 'tc34_' } } });
};
if (op === 'cleanup') await cleanup();
else if (op === 'seed') {
  await cleanup();
  const mk = async (tag, extra = {}) => prisma.user.create({ data: { name: `TC34 ${tag}`, email: `tc34_ui_${tag}@example.com`, password: await bcrypt.hash(PASSWORD, 10), role: 'user', isEmailVerified: true, ...extra } });
  const a = await mk('a', { interests: [], travelStyle: { budget: 500 } });
  const b = await mk('b');
  await mk('c');
  const trip = (title, creator, s, e, extra = {}) => prisma.trip.create({ data: { title, destination: 'Phuket', startDate: new Date(Date.now() + s * day), endDate: new Date(Date.now() + e * day), budget: 1000, category: 'ทะเล', maxParticipants: 5, creatorId: creator.id, participants: { create: { userId: creator.id, name: creator.name, interests: [] } }, ...extra } });
  await trip('TC34 A Future Trip', a, 5, 7);
  await trip('TC34 B Future Trip', b, 6, 8);
  await trip('TC34 Ended Trip', b, -10, -8);
  console.log('seeded');
}
await prisma.$disconnect();
