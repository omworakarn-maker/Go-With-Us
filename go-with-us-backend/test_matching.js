import { calculateTripCompatibilityDetailed } from './src/controllers/matchController.js';

// Mock trip and users
const trip = {
    budget: 2000,
    activityStyle: 5,
    timeOfDay: ["morning", "noon"],
    category: "คาเฟ่",
    creator: { travelStyle: { budget: 5, activityStyle: 5, timeOfDay: ["morning"] } },
    participants: [
        { user: { id: "p1", interests: ["คาเฟ่", "ถ่ายรูป"], travelStyle: { budget: 4, activityStyle: 6, timeOfDay: ["morning", "noon"] } } },
        { user: { id: "p2", interests: ["คาเฟ่"], travelStyle: { budget: 5, activityStyle: 4, timeOfDay: ["morning"] } } }
    ]
};

const userA = {
    id: "userA",
    interests: ["คาเฟ่", "ถ่ายรูป"],
    travelStyle: { budget: 5, activityStyle: 5, timeOfDay: ["morning", "noon"] }
};

const userB = {
    id: "userB",
    interests: ["ผจญภัย"],
    travelStyle: { budget: 2, activityStyle: 9, timeOfDay: ["night"] }
};

console.log("=== Match User A (Similar to group) ===");
const resA = calculateTripCompatibilityDetailed(userA, trip);
console.log(JSON.stringify(resA, null, 2));

console.log("\n=== Match User B (Very different) ===");
const resB = calculateTripCompatibilityDetailed(userB, trip);
console.log(JSON.stringify(resB, null, 2));
