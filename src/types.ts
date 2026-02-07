

export interface Trip {
  id: string;
  title: string;
  destination: string;
  description: string;
  startDate: string;
  endDate: string;
  budget: number;
  participants: Participant[];
  maxParticipants: number;
  itinerary?: DayPlan[];
  category?: string;
  creatorId?: string;
  creator?: {
    id: string;
    name: string;
    email: string;
    role: string;
  };
  imageUrl?: string;
  gallery?: string[]; // Additional images
  summary?: string;
  groupAnalysis?: string;
}


export interface TravelStyle {
  budget: 'budget' | 'moderate' | 'luxury';
  pace: 'relaxed' | 'moderate' | 'fast';
  interests: string[]; // e.g., ["Nature", "Culture"]
  social: 'solo' | 'small_group' | 'large_group';
  accommodation: 'hostel' | 'hotel' | 'resort' | 'camping';
  food?: 'street' | 'cafe' | 'local' | 'fine_dining';
  nightlife?: 'party' | 'chill' | 'quiet';
  transport?: 'public' | 'rent_car' | 'private_driver';
  photography?: 'pro' | 'instagram' | 'snap' | 'none';
}

export interface TripHistoryItem {
  tripId: string;
  role: 'creator' | 'participant';
  status: 'completed' | 'upcoming' | 'cancelled';
  joinedAt: string; // ISO Date string
}

export interface User {
  id: string;
  name: string;
  email: string;
  role: 'user' | 'admin';
  travelStyle?: TravelStyle;
  tripHistory?: TripHistoryItem[];
}

export interface Participant {
  id: string;
  name: string;
  interests: string[];
  dietaryRestrictions?: string;
}

export interface DayPlan {
  day: number;
  activities: Activity[];
}

export interface Activity {
  time: string;
  name: string;
  location: string;
  description: string;
}

export interface AIRecommendation {
  summary: string;
  itinerary: DayPlan[];
  groupAnalysis: string;
}

export interface Message {
  id: string;
  content: string;
  senderId: string;
  recipientId?: string;
  tripId?: string;
  createdAt: string;
  sender: {
    id: string;
    name: string;
    email: string;
  };
  recipient?: {
    id: string;
    name: string;
    email: string;
  };
}

export interface Conversation {
  user: {
    id: string;
    name: string;
    email: string;
  };
  lastMessage: Message;
}
