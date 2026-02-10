import admin from 'firebase-admin';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

let firebaseInitialized = false;

try {
    // 1. Try environment variable containing the JSON string
    if (process.env.FIREBASE_SERVICE_ACCOUNT) {
        const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
        admin.initializeApp({
            credential: admin.credential.cert(serviceAccount)
        });
        firebaseInitialized = true;
        console.log('✅ Firebase Admin initialized via environment variable.');
    }
    // 2. Try looking for serviceAccountKey.json in root or src
    else {
        const serviceAccountPath = path.resolve('serviceAccountKey.json');
        if (fs.existsSync(serviceAccountPath)) {
            admin.initializeApp({
                credential: admin.credential.cert(serviceAccountPath)
            });
            firebaseInitialized = true;
            console.log('✅ Firebase Admin initialized via local file.');
        } else {
            console.warn('⚠️ Firebase Admin config not found. Push notifications will be skipped.');
        }
    }
} catch (error) {
    console.error('❌ Failed to initialize Firebase Admin:', error.message);
}

export const sendPushNotification = async (fcmToken, title, body, data = {}) => {
    if (!firebaseInitialized || !fcmToken) return null;

    try {
        const message = {
            notification: {
                title,
                body,
            },
            data: {
                ...data,
                click_action: 'FLUTTER_NOTIFICATION_CLICK', // Standard for many cross-platform apps
            },
            token: fcmToken,
        };

        const response = await admin.messaging().send(message);
        console.log('🚀 Push Notification sent:', response);
        return response;
    } catch (error) {
        console.error('❌ Error sending push notification:', error);
        return null; // Don't throw, just return null
    }
};

export default admin;
