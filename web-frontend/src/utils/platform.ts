import { Capacitor } from '@capacitor/core';

/**
 * Check if the app is running on iOS native app (via Capacitor)
 */
export const isIOSApp = (): boolean => {
    return Capacitor.isNativePlatform() && Capacitor.getPlatform() === 'ios';
};

/**
 * Check if the app is running on Android native app (via Capacitor)
 */
export const isAndroidApp = (): boolean => {
    return Capacitor.isNativePlatform() && Capacitor.getPlatform() === 'android';
};

/**
 * Check if the app is running on any native platform (including Capacitor)
 * Returns true for iOS/Android apps built with Capacitor
 */
export const isNativeApp = (): boolean => {
    return Capacitor.isNativePlatform();
};

/**
 * Check if the app is running on web browser (desktop/mobile web, NOT Capacitor)
 */
export const isWebApp = (): boolean => {
    return !Capacitor.isNativePlatform();
};

/**
 * Check if running on mobile device (native or web)
 */
export const isMobile = (): boolean => {
    return Capacitor.isNativePlatform() || /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
};
