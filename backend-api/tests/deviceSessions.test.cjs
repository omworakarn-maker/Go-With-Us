const fs=require('node:fs'), assert=require('node:assert/strict'), crypto=require('node:crypto');
const {EventEmitter}=require('node:events');
const clean=s=>s.replace(/^import .*;\s*$/gm,'').replace(/export (const|class|async function|function) /g,'$1 ');
let rows=[], sequence=0, tail=Promise.resolve();
const activeMatch=(row,w={})=>Object.entries(w).every(([key,val])=>{
 if(key==='userId_deviceKey')return row.userId===val.userId&&row.deviceKey===val.deviceKey;
 if(val&&typeof val==='object'&&!(val instanceof Date)){
  if('lte'in val)return row[key]<=val.lte;if('gt'in val)return row[key]>val.gt;if('lt'in val)return row[key]<val.lt;if('not'in val)return row[key]!==val.not;if('in'in val)return val.in.includes(row[key]);
 }
 return row[key]===val;
});
const update=(row,data)=>{for(const[k,v]of Object.entries(data))row[k]=v&&typeof v==='object'&&'increment'in v?row[k]+v.increment:v;return structuredClone(row)};
const table={
 async findUnique({where}){return structuredClone(rows.find(r=>activeMatch(r,where))||null)},
 async findMany({where={},select}){let result=rows.filter(r=>activeMatch(r,where));if(select)result=result.map(r=>Object.fromEntries(Object.keys(select).map(k=>[k,r[k]])));return structuredClone(result)},
 async count({where}){return rows.filter(r=>activeMatch(r,where)).length},
 async create({data}){const now=new Date();const row={id:`session-${++sequence}`,version:1,createdAt:now,lastSeenAt:now,revokedAt:null,...data};rows.push(row);return structuredClone(row)},
 async upsert({where,create,update:data}){let row=rows.find(r=>activeMatch(r,where));return row?update(row,data):this.create({data:create})},
 async update({where,data}){const row=rows.find(r=>activeMatch(r,where));assert(row);return update(row,data)},
 async deleteMany({where}){const count=rows.filter(row=>activeMatch(row,where)).length;rows=rows.filter(row=>!activeMatch(row,where));return{count}},
 async updateMany({where,data}){const result=rows.filter(r=>activeMatch(r,where));result.forEach(row=>update(row,data));return{count:result.length}}
};
const prisma={deviceSession:table,async $transaction(fn){let release;const turn=new Promise(resolve=>release=resolve),previous=tail;tail=turn;await previous;const snapshot=structuredClone(rows);try{return await fn({deviceSession:table,async $queryRaw(strings,id){assert(strings.join('?').includes('FOR UPDATE'));return[{id}]}})}catch(e){rows=snapshot;throw e}finally{release()}}};
const service=new Function('crypto','EventEmitter','prisma',clean(fs.readFileSync(require('node:path').join(__dirname, '../src/utils/deviceSessions.js'),'utf8'))+'\nreturn {createDeviceSession,resolveDeviceSession,revokeDeviceSessions,listDeviceSessions,touchDeviceSession,sessionEvents,SessionError};')(crypto,EventEmitter,prisma);
const req=(device,user='u1',replacement)=>({body:{deviceId:device.padEnd(16,'x'),deviceName:device,replaceSessionId:replacement},headers:{'user-agent':'test browser'}});
const claims=(row)=>({userId:row.userId,sid:row.id,sessionVersion:row.version,exp:Math.floor(Date.now()/1000)+3600});
const response=()=>({status(code){this.statusCode=code;return this},json(body){this.body=body;return this}});
(async()=>{
 const starts=await Promise.allSettled(['a','b','c','d'].map(id=>service.createDeviceSession('u1',req(id))));
 assert.equal(starts.filter(r=>r.status==='fulfilled').length,3);const denied=starts.find(r=>r.status==='rejected').reason;assert.equal(denied.code,'DEVICE_LIMIT_REACHED');assert.equal(denied.sessions.length,3);
 assert(denied.sessions.every(s=>!('deviceKey'in s)&&!('token'in s)));
 const first=starts[0].value,second=starts[1].value,third=starts[2].value;
 const seen=[];service.sessionEvents.on('revoked',id=>seen.push(id));
 const again=await service.createDeviceSession('u1',req('a'));assert.equal(again.id,first.id);assert.equal(again.version,2);assert.equal(await table.count({where:{userId:'u1',revokedAt:null}}),3);
 await assert.rejects(service.resolveDeviceSession(claims(first),'token'),e=>e.code==='SESSION_REVOKED');assert.equal((await service.resolveDeviceSession(claims(again),'token')).id,first.id);
 await assert.rejects(service.createDeviceSession('u1',req('d','u1','foreign-session')),e=>e.code==='DEVICE_LIMIT_REACHED');
 const replacement=await service.createDeviceSession('u1',req('d','u1',second.id));assert(seen.includes(second.id));await assert.rejects(service.resolveDeviceSession(claims(second),'old-token'),e=>e.code==='SESSION_REVOKED');
 await assert.rejects(service.revokeDeviceSessions('u2',replacement.id,'not-owned'),e=>e.code==='SESSION_NOT_FOUND');
 await service.revokeDeviceSessions('u1',null,replacement.id,true);const list=await service.listDeviceSessions('u1',replacement.id);assert.equal(list.length,1);assert.equal(list[0].isCurrent,true);
 const legacyClaims={userId:'legacy',exp:Math.floor(Date.now()/1000)+3600};const legacy=await service.resolveDeviceSession(legacyClaims,'signed-legacy-token',{headers:{'user-agent':'old iPhone','x-device-id':'spoofed-device-123'}});
 assert.equal((await service.resolveDeviceSession(legacyClaims,'signed-legacy-token',{headers:{'x-device-id':'different-device-456'}})).id,legacy.id);
 await service.revokeDeviceSessions('legacy',legacy.id,legacy.id);await assert.rejects(service.resolveDeviceSession(legacyClaims,'signed-legacy-token',{headers:{'x-device-id':'fresh-device-789'}}),e=>e.code==='SESSION_REVOKED');
 const expired=await service.createDeviceSession('expired',req('phone'));rows.find(r=>r.id===expired.id).expiresAt=new Date(0);await assert.rejects(service.resolveDeviceSession(claims(expired),'token'),e=>e.code==='SESSION_REVOKED');
 const active=await service.createDeviceSession('ws',req('socket'));const other=await service.createDeviceSession('ws',req('other'));
 class FakeWSS extends EventEmitter{constructor(){super();this.clients=new Set()}}
 class Socket extends EventEmitter{constructor(){super();this.readyState=1;this.sent=[]}send(text){this.sent.push(JSON.parse(text))}close(code){this.closeCode=code;this.readyState=3;this.emit('close')}terminate(){this.terminated=true;this.close(1006)}ping(){this.pinged=true}}
 let heartbeat;const timers=new Set();
 const websocket=new Function('WebSocketServer','WebSocket','authenticateToken','prisma','sessionEvents','setTimeout','clearTimeout','setInterval','clearInterval','console',clean(fs.readFileSync(require('node:path').join(__dirname, '../src/utils/websocket.js'),'utf8'))+'\nreturn {initWebSocketServer};')(
  FakeWSS,{OPEN:1},async token=>{const row=token==='other'?other:active;await service.resolveDeviceSession(claims(row),token);return claims(row)},prisma,service.sessionEvents,fn=>{timers.add(fn);return fn},fn=>timers.delete(fn),fn=>{heartbeat=fn;return{unref(){}}},()=>{},{warn(){}}
 );
 const wss=websocket.initWebSocketServer({});const connect=()=>{const ws=new Socket();wss.clients.add(ws);ws.on('close',()=>wss.clients.delete(ws));wss.emit('connection',ws,{headers:{}});return ws};
 const settle=()=>new Promise(resolve=>setImmediate(resolve));
 const s1=connect();s1.emit('message',JSON.stringify({type:'auth',token:'main'}));await settle();assert.equal(s1.sent[0].type,'auth_success');
 const s2=connect();s2.emit('message',JSON.stringify({type:'auth',token:'main'}));await settle();assert.equal(s1.closeCode,4000);assert.equal(s2.readyState,1);
 const s3=connect();s3.emit('message',JSON.stringify({type:'auth',token:'other'}));await settle();
 await service.revokeDeviceSessions('ws',active.id,active.id);assert.equal(s2.closeCode,4001);assert.equal(s3.readyState,1);
 const stranger=connect();for(const fn of [...timers])fn();assert(stranger.terminated);
 await heartbeat();assert(s3.pinged);s3.emit('pong');await heartbeat();assert(!s3.terminated);await heartbeat();assert(s3.terminated);
 // Authentication rejects a revoked session, but a database failure remains a server error.
 const authSource=clean(fs.readFileSync(require('node:path').join(__dirname,'../src/middleware/auth.js'),'utf8'));
 const auth=new Function('jwt','resolveDeviceSession','touchDeviceSession','SessionError','console',authSource+'\nreturn {verifyToken,verifyTokenOptional};')(
  {verify(token){if(token==='expired'){const error=Error('expired');error.name='TokenExpiredError';throw error}return claims(token==='revoked'?active:other)}},
  async(c,t,r)=>{if(t==='database-failure')throw Object.assign(Error('Database unavailable'),{code:'P2024'});return service.resolveDeviceSession(c,t,r)},
  async()=>{},service.SessionError,{warn(){}}
 );
 let nextError;let authenticated=false;let result=response();
 await auth.verifyToken({headers:{authorization:'Bearer good'}},result,error=>{nextError=error;authenticated=!error});assert(authenticated);assert(!nextError);
 result=response();await auth.verifyToken({headers:{authorization:'Bearer revoked'}},result,()=>{throw Error('revoked session must not pass')});assert.equal(result.statusCode,401);assert.equal(result.body.code,'SESSION_REVOKED');
 result=response();await auth.verifyToken({headers:{authorization:'Bearer expired'}},result,()=>{throw Error('expired token must not pass')});assert.equal(result.statusCode,401);
 result=response();await auth.verifyToken({headers:{authorization:'Bearer database-failure'}},result,error=>nextError=error);assert.equal(nextError.code,'P2024');assert.equal(result.statusCode,undefined);
 let guest=false;await auth.verifyTokenOptional({headers:{}},response(),()=>guest=true);assert(guest);
 // The controller never exposes device choices until the password is verified.
 let passwordValid=false,sessionCreations=0;
 const loginSource=clean(fs.readFileSync(require('node:path').join(__dirname,'../src/controllers/authController.js'),'utf8'));
 const login=new Function('bcrypt','jwt','crypto','prisma','sendVerificationEmail','createDeviceSession','SESSION_LIFETIME_SECONDS',loginSource+'\nreturn login;')(
  {compare:async()=>passwordValid},{sign:payload=>JSON.stringify(payload)},crypto,{user:{findUnique:async()=>({id:'login-owner',email:'user@example.com',name:'User',password:'hash',role:'user',isEmailVerified:true})}},()=>{},
  async(id,r)=>{sessionCreations++;return service.createDeviceSession(id,r)},604800
 );
 const loginRequest=(device,replacement)=>({ ...req(device,'login-owner',replacement),body:{...req(device,'login-owner',replacement).body,email:'user@example.com',password:'not-logged'}});
 result=response();await login(loginRequest('phone'),result,error=>{throw error});assert.equal(result.statusCode,401);assert.equal(sessionCreations,0);
 passwordValid=true;
 for(const device of ['phone','tablet','browser']){result=response();await login(loginRequest(device),result,error=>{throw error});assert(JSON.parse(result.body.token).sid);}
 let limitError;result=response();await login(loginRequest('fourth'),result,error=>limitError=error);assert.equal(limitError.code,'DEVICE_LIMIT_REACHED');assert.equal(limitError.sessions.length,3);assert.equal(result.body,undefined);
 passwordValid=false;result=response();await login(loginRequest('fourth'),result,error=>{throw error});assert.equal(result.statusCode,401);assert(!result.body.sessions);
 console.log('PASS: device-session ownership, limits, rotation, legacy compatibility, and WebSocket lifecycle.');
})().catch(error=>{console.error(error);process.exitCode=1});
