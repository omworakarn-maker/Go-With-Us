// Persist membership events in the existing message table without a schema migration.
// The reserved prefix never reaches API clients: serialize it into a system message.
export const TRIP_JOIN_PREFIX = '\u001eGOWITHUS_MEMBER_JOINED:';

export const serializeTripChatMessage = message => {
    if (!message.content?.startsWith(TRIP_JOIN_PREFIX)) return message;
    return { ...message, content: message.content.slice(TRIP_JOIN_PREFIX.length), isSystem: true };
};

export async function saveTripMembership(prisma, { tripId, userId, name, interests, status, existing }) {
    return prisma.$transaction(async tx => {
        const data = { name, interests: interests || [], status: status || 'going' };
        let participant;
        let entered = false;
        if (existing) {
            // Conditional update prevents repeated joins from generating duplicate events.
            const transition = data.status === 'going' ? await tx.participant.updateMany({
                where: { tripId, userId, status: { not: 'going' } }, data
            }) : { count: 0 };
            entered = transition.count > 0;
            participant = await tx.participant.update({
                where: { tripId_userId: { tripId, userId } }, data
            });
        } else {
            participant = await tx.participant.create({ data: { ...data, tripId, userId } });
            entered = data.status === 'going';
        }
        const event = entered ? await tx.message.create({
            data: { tripId, senderId: userId, content: TRIP_JOIN_PREFIX + name + ' เข้าร่วมทริปแล้ว' },
            include: { sender: { select: { id: true, name: true, email: true, profileImage: true } } }
        }) : null;
        return { participant, event: event ? serializeTripChatMessage(event) : null };
    });
}
