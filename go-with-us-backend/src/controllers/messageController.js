import prisma from '../utils/prismaClient.js';
import { sendPushNotification } from '../utils/firebase.js';
import { sendMessageToUser } from '../utils/websocket.js';

// Get all messages for a trip (Group Chat)
export const getTripMessages = async (req, res, next) => {
    try {
        const { tripId } = req.params;

        // Check if user is a participant of the trip
        const participant = await prisma.participant.findFirst({
            where: {
                tripId,
                userId: req.user.userId,
            },
        });

        if (!participant) {
            return res.status(403).json({
                error: 'You must be a participant to view messages.'
            });
        }

        const messages = await prisma.message.findMany({
            where: { tripId },
            include: {
                sender: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        profileImage: true,
                    },
                },
            },
            orderBy: {
                createdAt: 'asc',
            },
        });

        // Mark corresponding notifications for this trip as read
        await prisma.notification.updateMany({
            where: {
                userId: req.user.userId,
                targetId: tripId,
                isRead: false
            },
            data: { isRead: true }
        });

        res.json({ messages });
    } catch (error) {
        next(error);
    }
};

// Send a message to a trip (Group Chat)
export const sendTripMessage = async (req, res, next) => {
    try {
        const { tripId } = req.params;
        const { content, imageUrl } = req.body;

        if ((!content || content.trim() === '') && !imageUrl) {
            return res.status(400).json({ error: 'Message content or image is required.' });
        }

        // Check if user is a participant
        const participant = await prisma.participant.findFirst({
            where: {
                tripId,
                userId: req.user.userId,
            },
        });

        if (!participant) {
            return res.status(403).json({
                error: 'You must be a participant to send messages.'
            });
        }

        const message = await prisma.message.create({
            data: {
                content: content?.trim() ?? '',
                imageUrl: imageUrl,
                senderId: req.user.userId,
                tripId,
            },
            include: {
                sender: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        profileImage: true,
                    },
                },
            },
        });

        res.status(201).json({ message });

        // --- NOTIFICATION LOGIC ---
        // Get all other participants to notify
        const otherParticipants = await prisma.participant.findMany({
            where: {
                tripId,
                userId: { not: req.user.userId }
            },
            include: {
                // We need to fetch the User to get the FCM token
                // But Prisma relation is Participant -> User (if defined in schema)
                // Let's check schema... Participant doesn't seem to have direct relation to User in provided schema snippet??
                // Wait, looking at schema provided earlier:
                // model Participant { ... userId String ... }
                // It does NOT have `user User @relation(...)` in the snippet I saw?
                // Let me re-read schema snippet.
                // Line 70: userId String
                // No relation field on Participant to User?
                // Wait, User model has: `trips Trip[]` but no `participants Participant[]`?
                // Actually looking at schema again:
                // model Participant { ... }
                // It does NOT show relation to User.
                // BUT `Trip` has `participants Participant[]`.
                // I might need to fetch User IDs from participants, then fetch Users.
            }
        });

        // Workaround if relation is missing or I missed it: Fetch users by IDs
        const recipientUserIds = otherParticipants.map(p => p.userId);

        if (recipientUserIds.length > 0) {
            const recipients = await prisma.user.findMany({
                where: { id: { in: recipientUserIds } },
                select: { id: true, fcmToken: true }
            });

            const trip = await prisma.trip.findUnique({ where: { id: tripId }, select: { title: true } });
            const title = `ข้อความใหม่ในทริป ${trip?.title || 'Group Chat'}`;
            const body = `${req.user.name || 'เพื่อน'}: ${content.substring(0, 50)}`;

            // Create Notifications, Send Push, and Send WebSockets
            await Promise.all(recipients.map(async (recipient) => {
                // Send WebSocket Realtime Message
                sendMessageToUser(recipient.id, message);
                
                // 1. DB Notification
                try {
                    await prisma.notification.create({
                        data: {
                            title,
                            message: body,
                            type: 'message', // or 'trip_message'
                            userId: recipient.id,
                            targetId: tripId
                        }
                    });
                } catch (e) {
                    console.error('Failed to create DB notification', e);
                }

                // 2. Push Notification
                if (recipient.fcmToken) {
                    await sendPushNotification(recipient.fcmToken, title, body, {
                        type: 'chat',
                        tripId: tripId
                    });
                }
            }));
        }

    } catch (error) {
        next(error);
    }
};

// Get private messages between two users
export const getPrivateMessages = async (req, res, next) => {
    try {
        const { userId } = req.params; // The other user ID
        const currentUserId = req.user.userId;

        const messages = await prisma.message.findMany({
            where: {
                AND: [
                    { tripId: null }, // Private messages only
                    {
                        OR: [
                            // Messages sent by current user to other user
                            {
                                senderId: currentUserId,
                                receiverId: userId,
                            },
                            // Messages sent by other user to current user
                            {
                                senderId: userId,
                                receiverId: currentUserId,
                            },
                        ],
                    },
                ],
            },
            include: {
                sender: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        profileImage: true,
                    },
                },
                receiver: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        profileImage: true,
                    },
                },
            },
            orderBy: {
                createdAt: 'asc',
            },
        });

        // Mark received messages as read
        await prisma.message.updateMany({
            where: {
                senderId: userId,
                receiverId: currentUserId,
                isRead: false
            },
            data: { isRead: true }
        });

        // Mark corresponding notifications as read
        await prisma.notification.updateMany({
            where: {
                userId: currentUserId,
                targetId: userId,
                type: 'message',
                isRead: false
            },
            data: { isRead: true }
        });

        res.json({ messages });
    } catch (error) {
        next(error);
    }
};

// Send a private message to another user
export const sendPrivateMessage = async (req, res, next) => {
    try {
        const { userId } = req.params; // Recipient ID
        const { content, imageUrl } = req.body;

        if ((!content || content.trim() === '') && !imageUrl) {
            return res.status(400).json({ error: 'Message content or image is required.' });
        }

        // Check if recipient exists
        const recipient = await prisma.user.findUnique({
            where: { id: userId },
            select: { id: true, fcmToken: true } // Fetch Token too
        });

        if (!recipient) {
            return res.status(404).json({ error: 'Recipient not found.' });
        }

        const message = await prisma.message.create({
            data: {
                content: content?.trim() ?? '',
                imageUrl: imageUrl,
                senderId: req.user.userId,
                receiverId: userId,
            },
            include: {
                sender: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        profileImage: true,
                    },
                },
                receiver: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        profileImage: true,
                    },
                },
            },
        });

        res.status(201).json({ message });

        // Create Notification for Recipient & Send Push
        const title = `ข้อความใหม่จาก ${req.user.name || 'เพื่อน'}`;
        const body = content.length > 50 ? content.substring(0, 50) + '...' : content;

        try {
            // Send WebSocket Realtime Message
            sendMessageToUser(userId, message);

            // 1. DB Notification
            await prisma.notification.create({
                data: {
                    title,
                    message: body,
                    type: 'message',
                    userId: userId, // Recipient
                    targetId: req.user.userId // Sender ID for navigation
                }
            });

            // 2. Push Notification
            if (recipient.fcmToken) {
                await sendPushNotification(recipient.fcmToken, title, body, {
                    type: 'private_chat',
                    senderId: req.user.userId
                });
            }

        } catch (notiError) {
            console.error('Failed to create notification or send push:', notiError);
        }

    } catch (error) {
        next(error);
    }
};

// Get all conversations (list of users you've chatted with)
export const getConversations = async (req, res, next) => {
    try {
        const currentUserId = req.user.userId;

        // Get all private messages involving current user
        const messages = await prisma.message.findMany({
            where: {
                AND: [
                    { tripId: null },
                    {
                        OR: [
                            { senderId: currentUserId },
                            { receiverId: currentUserId },
                        ],
                    },
                ],
            },
            include: {
                sender: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        profileImage: true,
                    },
                },
                receiver: {
                    select: {
                        id: true,
                        name: true,
                        email: true,
                        profileImage: true,
                    },
                },
            },
            orderBy: {
                createdAt: 'desc',
            },
        });

        // Extract unique users and calculate unread counts
        const userMap = new Map();

        messages.forEach(msg => {
            const isMeSender = msg.senderId === currentUserId;
            const otherUser = isMeSender ? msg.receiver : msg.sender;

            if (otherUser) {
                if (!userMap.has(otherUser.id)) {
                    userMap.set(otherUser.id, {
                        user: otherUser,
                        lastMessage: msg,
                        unreadCount: 0
                    });
                }

                // Increment unread count if I am the receiver and message is not read
                if (!isMeSender && !msg.isRead) {
                    const data = userMap.get(otherUser.id);
                    data.unreadCount += 1;
                }
            }
        });

        const conversations = Array.from(userMap.values());

        res.json({ conversations });
    } catch (error) {
        next(error);
    }
};

// Delete a conversation with a specific user
export const deleteConversation = async (req, res, next) => {
    try {
        const { userId } = req.params; // The other user ID
        const currentUserId = req.user.userId;

        await prisma.message.deleteMany({
            where: {
                AND: [
                    { tripId: null }, // Private messages only
                    {
                        OR: [
                            { senderId: currentUserId, receiverId: userId },
                            { senderId: userId, receiverId: currentUserId }
                        ]
                    }
                ]
            }
        });

        // Also delete the match record so they are fully unmatched
        await prisma.userMatch.deleteMany({
            where: {
                OR: [
                    { likerId: currentUserId, likedId: userId },
                    { likerId: userId, likedId: currentUserId }
                ]
            }
        });

        res.json({ message: 'Conversation deleted successfully' });
    } catch (error) {
        next(error);
    }
};

// Delete a single message (Unsend)
export const deleteMessage = async (req, res, next) => {
    try {
        const { messageId } = req.params;
        const currentUserId = req.user.userId;

        const message = await prisma.message.findUnique({
            where: { id: messageId }
        });

        if (!message) {
            return res.status(404).json({ error: 'Message not found' });
        }

        // Only the sender or an admin can delete a message
        if (message.senderId !== currentUserId && req.user.role !== 'admin') {
            return res.status(403).json({ error: 'You do not have permission to delete this message.' });
        }

        await prisma.message.delete({
            where: { id: messageId }
        });

        res.json({ message: 'Message deleted successfully' });
    } catch (error) {
        next(error);
    }
};
