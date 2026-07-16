import { calculateTripCompatibilityDetailed } from './src/controllers/matchController.js';

const user = {
    travelStyle: {
        budget: 3000,
        activityStyle: 5,
        timeOfDay: ["morning", "afternoon", "evening", "night", "late_night", "all_day"]
    },
    interests: ["nature"]
};

const trip = {
    budget: 3000,
    activityStyle: 5,
    timeOfDay: ["morning"],
    category: "nature"
};

const result = calculateTripCompatibilityDetailed(user, trip);
console.log(result);
