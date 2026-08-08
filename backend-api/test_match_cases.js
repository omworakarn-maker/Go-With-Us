import { calculateTripCompatibilityDetailed } from './src/controllers/matchController.js';

const baseTrip = {
  budget: 2000,
  activityStyle: 5,
  timeOfDay: ['morning', 'noon'],
  category: 'คาเฟ่',
  creator: { travelStyle: { budget: 5, activityStyle: 5, timeOfDay: ['morning', 'noon'] } },
  participants: []
};

const cases = [
  ['ใกล้เคียงทุกด้าน', ['คาเฟ่'], { budget: 5, activityStyle: 5, timeOfDay: ['morning', 'noon'] }],
  ['ใกล้เคียงบางส่วน (งบและกิจกรรมตรง)', ['ภูเขา'], { budget: 5, activityStyle: 5, timeOfDay: ['night'] }],
  ['งบประมาณต่างมาก', ['คาเฟ่'], { budget: 1, activityStyle: 5, timeOfDay: ['morning', 'noon'] }],
  ['สไตล์กิจกรรมต่างมาก', ['คาเฟ่'], { budget: 5, activityStyle: 10, timeOfDay: ['morning', 'noon'] }],
  ['หมวดหมู่ไม่ตรง', ['ผจญภัย'], { budget: 5, activityStyle: 5, timeOfDay: ['morning', 'noon'] }],
  ['ช่วงเวลาไม่ตรง', ['คาเฟ่'], { budget: 5, activityStyle: 5, timeOfDay: ['night'] }],
  ['ไม่ใกล้เคียงทุกด้าน', ['ผจญภัย'], { budget: 1, activityStyle: 10, timeOfDay: ['night'] }]
];

console.log('=== ผลการทดสอบระบบ Smart Matching ===');
for (const [name, interests, travelStyle] of cases) {
  const result = calculateTripCompatibilityDetailed({ interests, travelStyle }, baseTrip);
  console.log(`\nกรณี: ${name}`);
  console.log(`Match Score: ${result.total}%`);
  console.log(`งบ ${result.breakdown.budget}% | กิจกรรม ${result.breakdown.activityStyle}% | หมวดหมู่ ${result.breakdown.category}% | ช่วงเวลา ${result.breakdown.timeOfDay}%`);
}
