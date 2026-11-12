import assert from 'node:assert/strict';
import { saveTripMembership, serializeTripChatMessage, TRIP_JOIN_PREFIX } from '../src/utils/tripChatEvents.js';

const input = { tripId: 'trip-1', userId: 'user-1', name: 'Friend', interests: [], status: 'going', existing: false };
function database(initial = null, failEvent = false) {
    const state = { participant: initial, events: [] };
    return {
        state,
        async $transaction(work) {
            const before = structuredClone(state);
            const tx = {
                participant: {
                    async create({ data }) { state.participant = { id: 'participant-1', ...data }; return state.participant; },
                    async updateMany({ data }) {
                        if (state.participant.status === 'going') return { count: 0 };
                        Object.assign(state.participant, data); return { count: 1 };
                    },
                    async update({ data }) { Object.assign(state.participant, data); return state.participant; }
                },
                message: {
                    async create({ data }) {
                        if (failEvent) throw new Error('event insert failed');
                        const event = { id: 'event-' + state.events.length, ...data };
                        state.events.push(event); return event;
                    }
                }
            };
            try { return await work(tx); }
            catch (error) { Object.assign(state, before); throw error; }
        }
    };
}

const db = database();
const joined = await saveTripMembership(db, input);
assert.equal(joined.event.isSystem, true);
assert.equal(joined.event.content, 'Friend เข้าร่วมทริปแล้ว');
assert.equal(joined.event.tripId, input.tripId);
assert(!joined.event.content.includes(TRIP_JOIN_PREFIX));
assert.equal(db.state.events.length, 1);
assert.equal((await saveTripMembership(db, { ...input, existing: true })).event, null);
assert.equal(db.state.events.length, 1, 'editing membership must not duplicate join events');

const interested = database();
assert.equal((await saveTripMembership(interested, { ...input, status: 'interested' })).event, null);
assert.equal(interested.state.events.length, 0);
assert.equal((await saveTripMembership(interested, { ...input, existing: true })).event.isSystem, true);
assert.equal(interested.state.events.length, 1, 'interested to going emits one event');

const failing = database(null, true);
await assert.rejects(saveTripMembership(failing, input), /event insert failed/);
assert.equal(failing.state.participant, null, 'membership rolls back if event persistence fails');

const ordinary = { content: 'Hello', id: 'normal' };
assert.strictEqual(serializeTripChatMessage(ordinary), ordinary);
console.log('PASS: join events, repeat joins, interested transitions, rollback, and safe serialization');
