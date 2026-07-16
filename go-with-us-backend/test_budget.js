import { calculateTripCompatibilityDetailed } from './src/controllers/matchController.js';
console.log(calculateTripCompatibilityDetailed(
    { travelStyle: { budget: 3000 } },
    { budget: 3000 }
));
