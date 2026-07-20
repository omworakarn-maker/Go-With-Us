const configuredSecret = process.env.JWT_SECRET;

if (!configuredSecret && process.env.NODE_ENV === 'production') {
    throw new Error('JWT_SECRET must be configured in production');
}

// A deterministic fallback keeps local development usable; production must set JWT_SECRET.
export const authSecret = configuredSecret || 'development-only-secret';
