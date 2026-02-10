
import { authFetch } from './api';

const API_Base = import.meta.env.VITE_API_URL || '/api';

export interface MatchUser {
    id: string;
    name: string;
    interests: string[];
    matchScore: number;
    avatar?: string;
}

export interface MatchTrip {
    id: string;
    title: string;
    destination: string;
    category: string;
    startDate: string;
    imageUrl?: string;
    matchScore: number;
    creator: {
        id: string;
        name: string;
    };
    participants: {
        id: string;
    }[];
}

export const matchAPI = {
    // Get matched buddies
    getBuddyMatches: async (): Promise<{ matches: MatchUser[] }> => {
        return authFetch(`${API_Base}/match/buddy`);
    },

    // Get matched trips
    getTripMatches: async (): Promise<{ matches: MatchTrip[] }> => {
        return authFetch(`${API_Base}/match/trips`);
    }
};
