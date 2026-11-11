const assert = require('node:assert/strict');
const { repairLabel, repairLabels } = require('../scripts/repair-interest-encoding.cjs');

assert.equal(repairLabel('‡∏ó‡∏∞‡πÄ‡∏•'), 'ทะเล');
assert.equal(repairLabel('ภูเขา'), 'ภูเขา');
assert.deepEqual(repairLabels(['‡∏ó‡∏∞‡πÄ‡∏•', 'ทะเล', 'คาเฟ่']), ['ทะเล', 'คาเฟ่']);
console.log('interest encoding repair tests passed');
