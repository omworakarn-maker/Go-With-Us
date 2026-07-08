import { WebSocketServer } from 'ws';
import jwt from 'jsonwebtoken';

let wss;
const clients = new Map(); // userId -> Set of WebSocket instances

export const initWebSocketServer = (server) => {
    wss = new WebSocketServer({ server });

    wss.on('connection', (ws, req) => {
        let userId = null;

        ws.on('message', (message) => {
            try {
                const data = JSON.parse(message);
                
                // Handle Authentication
                if (data.type === 'auth') {
                    const token = data.token;
                    if (!token) return;

                    jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key', (err, decoded) => {
                        if (err) {
                            ws.send(JSON.stringify({ type: 'error', message: 'Authentication failed' }));
                            ws.close();
                            return;
                        }

                        userId = decoded.userId;
                        if (!clients.has(userId)) {
                            clients.set(userId, new Set());
                        }
                        clients.get(userId).add(ws);
                        ws.send(JSON.stringify({ type: 'auth_success' }));
                        console.log(`🔌 User ${userId} connected to WebSocket`);
                    });
                }
            } catch (error) {
                console.error('WebSocket message error:', error);
            }
        });

        ws.on('close', () => {
            if (userId && clients.has(userId)) {
                clients.get(userId).delete(ws);
                if (clients.get(userId).size === 0) {
                    clients.delete(userId);
                }
                console.log(`🔌 User ${userId} disconnected from WebSocket`);
            }
        });
    });
};

export const sendMessageToUser = (userId, messageObj) => {
    if (clients.has(userId)) {
        const userSockets = clients.get(userId);
        const payload = JSON.stringify({
            type: 'new_message',
            message: messageObj
        });
        
        for (const ws of userSockets) {
            if (ws.readyState === ws.OPEN) {
                ws.send(payload);
            }
        }
    }
};
