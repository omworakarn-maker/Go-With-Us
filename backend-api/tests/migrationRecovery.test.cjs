const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const { inspectMigration } = require('../scripts/recover-registration-migration.cjs');
const sql = fs.readFileSync(path.join(__dirname, '../prisma/migrations/20260907143000_add_pending_registrations/migration.sql'));
const checksum = crypto.createHash('sha256').update(sql).digest('hex');
const expected = ['email','name','password_hash','otp_code','otp_expires_at','created_at','updated_at'];
const columns = expected.map(name => ({column_name:name, data_type:name.endsWith('_at')?'timestamp without time zone':'text',is_nullable:'NO',column_default:name==='created_at'?'CURRENT_TIMESTAMP':null,datetime_precision:name.endsWith('_at')?3:null}));
function db(options={}) {
 return {async $queryRaw(strings) {
  const query=strings.join('?');
  if(query.includes('to_regclass'))return [{registration_table:options.absent?null:'pending_registrations',migration_table:options.noHistory?null:'_prisma_migrations'}];
  if(query.includes('SELECT checksum'))return options.applied?[{finished_at:new Date(),rolled_back_at:null}]:[{checksum:options.badChecksum?'bad':checksum,finished_at:null,rolled_back_at:null}];
  if(query.includes('information_schema.columns'))return options.columns||columns;
  if(query.includes('table_constraints'))return options.key||[{column_name:'email',constraint_name:'pending_registrations_pkey'}];
  throw Error('Unexpected query');
 }};
}
(async()=>{
 assert.equal(await inspectMigration(db(),sql),true);
 assert.equal(await inspectMigration(db({absent:true}),sql),false);
 assert.equal(await inspectMigration(db({applied:true}),sql),false);
 await assert.rejects(inspectMigration(db({noHistory:true}),sql),/baseline/);
 await assert.rejects(inspectMigration(db({columns:columns.slice(1)}),sql),/column count/);
 await assert.rejects(inspectMigration(db({columns:columns.map(c=>c.column_name==='email'?{...c,is_nullable:'YES'}:c)}),sql),/email/);
 await assert.rejects(inspectMigration(db({columns:columns.map(c=>c.column_name==='otp_code'?{...c,data_type:'integer'}:c)}),sql),/otp_code/);
 await assert.rejects(inspectMigration(db({columns:columns.map(c=>c.column_name==='updated_at'?{...c,datetime_precision:6}:c)}),sql),/updated_at/);
 await assert.rejects(inspectMigration(db({columns:columns.map(c=>c.column_name==='created_at'?{...c,column_default:null}:c)}),sql),/created_at/);
 await assert.rejects(inspectMigration(db({key:[{column_name:'name',constraint_name:'pending_registrations_pkey'}]}),sql),/primary key/);
 await assert.rejects(inspectMigration(db({badChecksum:true}),sql),/checksum/);
 console.log('PASS: 11 migration-history checks; only an exact existing table can be marked applied.');
})().catch(error=>{console.error(error);process.exitCode=1});
