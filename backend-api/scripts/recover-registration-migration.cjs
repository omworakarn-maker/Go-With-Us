const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const { execFileSync } = require('node:child_process');

const MIGRATION = '20260907143000_add_pending_registrations';
const expected = [
    ['email', 'text'], ['name', 'text'], ['password_hash', 'text'], ['otp_code', 'text'],
    ['otp_expires_at', 'timestamp without time zone'],
    ['created_at', 'timestamp without time zone'], ['updated_at', 'timestamp without time zone']
];

async function inspectMigration(db, migrationSQL) {
    const [tables] = await db.$queryRaw`SELECT to_regclass('public.pending_registrations')::text AS registration_table, to_regclass('public._prisma_migrations')::text AS migration_table`;
    if (!tables.registration_table) return false;
    if (!tables.migration_table) throw new Error('Existing registration table has no Prisma migration history; baseline review is required.');

    const history = await db.$queryRaw`SELECT checksum, finished_at, rolled_back_at FROM public._prisma_migrations WHERE migration_name = ${MIGRATION} ORDER BY started_at DESC`;
    if (history.some(item => item.finished_at && !item.rolled_back_at)) return false;

    const columns = await db.$queryRaw`SELECT column_name, data_type, is_nullable, column_default, datetime_precision FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'pending_registrations' ORDER BY ordinal_position`;
    if (columns.length !== expected.length) throw new Error('Registration table differs from the migration: unexpected column count.');
    for (const [name, type] of expected) {
        const column = columns.find(item => item.column_name === name);
        if (!column || column.data_type !== type || column.is_nullable !== 'NO' ||
            (type.startsWith('timestamp') && column.datetime_precision !== 3)) {
            throw new Error(`Registration table differs from the migration at column ${name}.`);
        }
        if (name === 'created_at') {
            const value = String(column.column_default || '').replace(/\s/g, '').toUpperCase();
            if (!['CURRENT_TIMESTAMP', 'CURRENT_TIMESTAMP(3)', 'NOW()'].includes(value)) {
                throw new Error('Registration table has an unexpected created_at default.');
            }
        } else if (column.column_default !== null) {
            throw new Error(`Registration table has an unexpected default at column ${name}.`);
        }
    }
    const key = await db.$queryRaw`SELECT kcu.column_name, tc.constraint_name FROM information_schema.table_constraints tc JOIN information_schema.key_column_usage kcu ON tc.constraint_catalog = kcu.constraint_catalog AND tc.constraint_schema = kcu.constraint_schema AND tc.constraint_name = kcu.constraint_name WHERE tc.table_schema = 'public' AND tc.table_name = 'pending_registrations' AND tc.constraint_type = 'PRIMARY KEY' ORDER BY kcu.ordinal_position`;
    if (key.length !== 1 || key[0].column_name !== 'email' || key[0].constraint_name !== 'pending_registrations_pkey') {
        throw new Error('Registration table primary key differs from the migration.');
    }
    const checksum = crypto.createHash('sha256').update(migrationSQL).digest('hex');
    if (history.some(item => !item.finished_at && !item.rolled_back_at && item.checksum !== checksum)) {
        throw new Error('Failed registration migration checksum differs; manual history review is required.');
    }
    return true;
}

async function main() {
    require('dotenv').config();
    const { PrismaClient } = require('@prisma/client');
    const url = process.env.DIRECT_DATABASE_URL || process.env.DATABASE_URL;
    if (!url) throw new Error('Database URL is not configured.');
    const db = new PrismaClient({ datasources: { db: { url } } });
    let resolve = false;
    try {
        const sql = fs.readFileSync(path.join(__dirname, '..', 'prisma', 'migrations', MIGRATION, 'migration.sql'));
        resolve = await inspectMigration(db, sql);
    } finally { await db.$disconnect(); }
    if (!resolve) return;
    console.log('Verified existing registration table; reconciling Prisma history without recreating it.');
    try {
        execFileSync('prisma', ['migrate', 'resolve', '--applied', MIGRATION], { stdio: 'pipe' });
    } catch (error) {
        const output = `${error.stdout || ''}\n${error.stderr || ''}`;
        // Another deployment may have resolved the same history after our check.
        if (!output.includes('P3008')) throw new Error(output || error.message);
    }
    console.log('Registration migration history reconciled.');
}

module.exports = { inspectMigration, MIGRATION };
if (require.main === module) main().catch(error => { console.error(error.message); process.exitCode = 1; });
