const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../src/controllers/notificationController.js'), 'utf8')
    .replace(/^import .*;$/gm, '').replaceAll('export const ', 'const ');
const calls = [];
const prisma = { notification: {
    async findMany(query) { calls.push(query); return []; },
    async count(query) { calls.push(query); return 0; }
} };
const handlers = new Function('prisma', source + '\nreturn { getNotifications, getUnreadCount };')(prisma);
const response = { json() {} };
const next = error => { throw error; };
(async () => {
    const req = { user: { userId: 'member', role: 'user' }, query: {} };
    await handlers.getNotifications(req, response, next);
    assert(calls.at(-1).where.type.notIn.includes('message'));
    assert.deepEqual(calls.at(-1).where.OR, [{ userId: 'member' }, { userId: null }]);
    await handlers.getUnreadCount(req, response, next);
    assert(calls.at(-1).where.type.notIn.includes('message'));
    assert.equal(calls.at(-1).where.userId, 'member');
    await handlers.getNotifications({ ...req, query: { includeMessages: 'true' } }, response, next);
    assert.equal(calls.at(-1).where.type, undefined, 'sender-specific banner polling can still read chat alerts');
    await handlers.getNotifications({ ...req, query: { all: 'true' } }, response, next);
    assert(calls.at(-1).where.type, 'non-admin cannot bypass inbox filtering with all=true');
    console.log('PASS: chat alerts excluded from inbox and unread count; banner polling retained; user scope preserved');
})();
