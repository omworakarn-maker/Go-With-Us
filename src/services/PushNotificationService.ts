import { PushNotifications } from '@capacitor/push-notifications';
import { userAPI } from './api';
import { Capacitor } from '@capacitor/core';

export const PushNotificationService = {
    init: async () => {
        if (!Capacitor.isNativePlatform()) {
            console.log('Push Notifications are only supported on native devices.');
            return;
        }

        try {
            // 1. Request Permission
            let permStatus = await PushNotifications.checkPermissions();

            if (permStatus.receive === 'prompt') {
                permStatus = await PushNotifications.requestPermissions();
            }

            if (permStatus.receive !== 'granted') {
                console.error('User denied push notification permissions');
                return;
            }

            // 2. Register
            await PushNotifications.register();

            // 3. Add Listeners
            PushNotificationService.addListeners();

        } catch (e) {
            console.error('Failed to initialize push notifications', e);
        }
    },

    addListeners: () => {
        // On success registration
        PushNotifications.addListener('registration', async (token) => {
            console.log('Push Registration Success. Token:', token.value);
            try {
                // Send token to backend
                await userAPI.registerDeviceToken(token.value);
                console.log('Device token sent to backend successfully');
            } catch (error) {
                console.error('Failed to send device token to backend', error);
            }
        });

        // On registration error
        PushNotifications.addListener('registrationError', (error) => {
            console.error('Push Registration Error:', error);
        });

        // On notification received (active app)
        PushNotifications.addListener('pushNotificationReceived', (notification) => {
            console.log('Push Received:', notification);
            // You can implement in-app toast/banner here if needed
        });

        // On notification action (tapped)
        PushNotifications.addListener('pushNotificationActionPerformed', (notification) => {
            console.log('Push Action Performed:', notification);
            // You can navigate based on notification.data here
            // const data = notification.notification.data;
            // if (data.tripId) navigate(`/trip/${data.tripId}`);
        });
    }
};
