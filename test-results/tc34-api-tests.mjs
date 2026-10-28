// TC-34+ API-level checks against a locally running backend (http://localhost:3000).
// Creates users/trips prefixed "tc34_" in the database and removes them at the end.
// Usage: node test-results/tc34-api-tests.mjs   (backend must be running)
import bcrypt from '../backend-api/node_modules/bcryptjs/index.js';
import { writeFileSync } from 'node:fs';
import prisma from '../backend-api/src/utils/prismaClient.js';

const BASE = process.env.BASE_URL || 'http://localhost:3000/api';
const RUN = Date.now();
const email = (tag) => `tc34_${tag}_${RUN}@example.com`;
const PASSWORD = 'Tc34Password!';
const results = [];
const record = (id, name, expected, actual, pass) => {
    results.push({ id, name, expected, actual, pass });
    console.log(`${pass ? 'PASS' : 'FAIL'}  ${id}  ${name}\n      expected: ${expected}\n      actual:   ${actual}`);
};

const call = async (method, path, { token, body } = {}) => {
    const res = await fetch(BASE + path, {
        method,
        headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
        body: body ? JSON.stringify(body) : undefined,
    });
    let json = null;
    try { json = await res.json(); } catch { /* empty body */ }
    return { status: res.status, json };
};

const createdUserIds = [];
const makeUser = async (tag, extra = {}) => {
    const user = await prisma.user.create({
        data: {
            name: `TC34 ${tag}`, email: email(tag), password: await bcrypt.hash(PASSWORD, 10),
            role: 'user', isEmailVerified: true, ...extra,
        },
    });
    createdUserIds.push(user.id);
    const login = await call('POST', '/auth/login', { body: { email: user.email, password: PASSWORD } });
    return { user, token: login.json?.token };
};

const day = 86400000;
const iso = (offsetDays) => new Date(Date.now() + offsetDays * day).toISOString();

try {
    const A = await makeUser('a', {
        interests: [],
        travelStyle: { budget: 500 }, // answered budget only; activity/time/category left blank
    });
    const B = await makeUser('b');
    const C = await makeUser('c');

    // Trip owned by A, in the future
    const tripRes = await call('POST', '/trips', {
        token: A.token,
        body: { title: 'tc34 future trip', destination: 'Phuket', startDate: iso(5), endDate: iso(7), budget: 1000, category: 'ทะเล', maxParticipants: 5 },
    });
    const tripId = tripRes.json?.trip?.id;

    // ---- TC-34 partial preferences -> average only available factors
    const m = await call('GET', '/match/trips', { token: A.token });
    const mine = m.json?.matches?.find((t) => t.id === tripId);
    const bd = mine?.matchBreakdown;
    const nonNull = bd ? Object.entries(bd).filter(([k, v]) => k !== 'groupMatch' && v !== null) : [];
    const expectedScore = nonNull.length ? Math.round(nonNull.reduce((s, [, v]) => s + v, 0) / nonNull.length) : null;
    record('TC-34', 'Missing preference answers: score averages only answered factors',
        'budget=50 (500/1000) is the only factor; matchScore=50; other factors null',
        `status=${m.status}, matchScore=${mine?.matchScore}, breakdown=${JSON.stringify(bd)}`,
        m.status === 200 && !!mine && nonNull.length === 1 && mine.matchScore === expectedScore && mine.matchScore === 50);

    // ---- TC-35 ended trip excluded from recommendations
    const past = await prisma.trip.create({
        data: { title: 'tc34 ended trip', destination: 'Krabi', startDate: new Date(Date.now() - 10 * day), endDate: new Date(Date.now() - 8 * day), creatorId: A.user.id, category: 'ทะเล' },
    });
    const m2 = await call('GET', '/match/trips', { token: B.token });
    const ids = (m2.json?.matches || []).map((t) => t.id);
    record('TC-35', 'Ended trip is not shown in recommended list',
        'ended trip id absent from /match/trips, future trip present',
        `status=${m2.status}, endedTripListed=${ids.includes(past.id)}, futureTripListed=${ids.includes(tripId)}`,
        m2.status === 200 && !ids.includes(past.id) && ids.includes(tripId));

    // ---- TC-36 wrong / expired OTP
    const otpMail = email('otp');
    const knownOtp = '123456';
    await prisma.pendingRegistration.create({
        data: { name: 'TC34 otp', email: otpMail, passwordHash: await bcrypt.hash(PASSWORD, 10), otpCode: await bcrypt.hash(knownOtp, 10), otpExpiresAt: new Date(Date.now() + 600000) },
    });
    const wrong = await call('POST', '/auth/verify-otp', { body: { email: otpMail, otp: '000000' } });
    record('TC-36a', 'Wrong OTP is rejected', '400 Invalid OTP, no account created',
        `status=${wrong.status}, body=${JSON.stringify(wrong.json)}`, wrong.status === 400 && /invalid/i.test(wrong.json?.error || ''));
    await prisma.pendingRegistration.update({ where: { email: otpMail }, data: { otpExpiresAt: new Date(Date.now() - 60000) } });
    const expired = await call('POST', '/auth/verify-otp', { body: { email: otpMail, otp: knownOtp } });
    const created = await prisma.user.findUnique({ where: { email: otpMail } });
    record('TC-36b', 'Correct but expired OTP is rejected', '400 OTP has expired, no account created',
        `status=${expired.status}, body=${JSON.stringify(expired.json)}, accountCreated=${!!created}`,
        expired.status === 400 && /expired/i.test(expired.json?.error || '') && !created);

    // ---- TC-37 duplicate email
    const dup = await call('POST', '/auth/register', { body: { name: 'dup', email: A.user.email, password: PASSWORD } });
    record('TC-37', 'Register with an email that already exists', '400 Email already registered',
        `status=${dup.status}, body=${JSON.stringify(dup.json)}`, dup.status === 400 && /already registered/i.test(dup.json?.error || ''));

    // ---- TC-38 join same trip twice
    const j1 = await call('POST', `/trips/${tripId}/join`, { token: B.token, body: { name: 'TC34 b', interests: [], status: 'going' } });
    const j2 = await call('POST', `/trips/${tripId}/join`, { token: B.token, body: { name: 'TC34 b', interests: [], status: 'going' } });
    const rows = await prisma.participant.count({ where: { tripId, userId: B.user.id } });
    record('TC-38', 'Join the same trip twice',
        'first 201; second must not create a duplicate (participant rows for user = 1)',
        `first=${j1.status}, second=${j2.status} ${JSON.stringify(j2.json?.message || j2.json)}, participantRows=${rows}`,
        j1.status === 201 && rows === 1 && j2.status !== 201);

    // ---- TC-39 non-owner edit / delete
    const edit = await call('PUT', `/trips/${tripId}`, { token: C.token, body: { title: 'hijacked' } });
    const del = await call('DELETE', `/trips/${tripId}`, { token: C.token });
    const still = await prisma.trip.findUnique({ where: { id: tripId } });
    record('TC-39', 'Non-owner edits / deletes a trip', '403 for both, trip unchanged',
        `edit=${edit.status}, delete=${del.status}, title="${still?.title}", exists=${!!still}`,
        edit.status === 403 && del.status === 403 && still?.title === 'tc34 future trip');

    // ---- Postman IT-06 replica (see 3.68): User B joins a fresh trip created by A
    const t2 = await call('POST', '/trips', { token: A.token, body: { title: 'tc34 it06', destination: 'Phuket', startDate: iso(5), endDate: iso(7), budget: 1000, category: 'ทะเล' } });
    const t2id = t2.json?.trip?.id;
    const it06 = await call('POST', `/trips/${t2id}/join`, { token: B.token, body: { name: 'Integration User B', interests: ['ทะเล', 'ถ่ายรูป'], status: 'going' } });
    record('IT-06', 'Postman join trip: user B joins trip created by A', 'status 201 (assertion in collection)',
        `status=${it06.status}, body=${JSON.stringify(it06.json)}`, it06.status === 201);
    const it06creator = await call('POST', `/trips/${t2id}/join`, { token: A.token, body: { name: 'Integration User A', interests: [], status: 'going' } });
    record('IT-06-owner', 'Join using the CREATOR token (creator is auto-added as participant)', 'informational: status returned',
        `status=${it06creator.status}, message=${it06creator.json?.message}`, true);
} catch (e) {
    console.error('Harness error:', e);
    results.push({ id: 'HARNESS', name: 'script error', expected: 'no error', actual: String(e), pass: false });
} finally {
    await prisma.trip.deleteMany({ where: { creatorId: { in: createdUserIds } } });
    await prisma.pendingRegistration.deleteMany({ where: { email: { startsWith: 'tc34_' } } });
    await prisma.user.deleteMany({ where: { id: { in: createdUserIds } } });
    writeFileSync(new URL('./tc34-api-results.json', import.meta.url), JSON.stringify(results, null, 2));
    await prisma.$disconnect();
}
