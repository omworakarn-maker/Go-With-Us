const fs=require('node:fs'), assert=require('node:assert/strict'), crypto=require('node:crypto'), ts=require('typescript');
const settle=()=>new Promise(resolve=>setImmediate(resolve));
(async()=>{
 const exports={};const storage=new Map();const localStorage={getItem:k=>storage.get(k)||null,setItem:(k,v)=>storage.set(k,v)};
 const deviceSource=ts.transpileModule(fs.readFileSync(require('node:path').join(__dirname, '../src/services/deviceIdentity.ts'),'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.CommonJS}}).outputText;
 new Function('exports','localStorage','crypto','navigator',deviceSource)(exports,localStorage,crypto,{userAgent:'iPhone Safari/605'});assert.equal(exports.getDeviceIdentity().deviceId,exports.getDeviceIdentity().deviceId);
 let refreshes=0,runTick,visibility;const doc={visibilityState:'hidden',addEventListener:(type,fn)=>visibility=fn,removeEventListener:()=>visibility=null};const win={setInterval:fn=>{runTick=fn;return 1},clearInterval:()=>{}};
 const pollExports={};const pollSource=ts.transpileModule(fs.readFileSync(require('node:path').join(__dirname, '../src/services/visiblePolling.ts'),'utf8'),{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.CommonJS}}).outputText;
 new Function('exports','window','document',pollSource)(pollExports,win,doc);let done;const stop=pollExports.startVisiblePolling(()=>{refreshes++;return new Promise(resolve=>done=resolve)},3000);
 await runTick();assert.equal(refreshes,0);doc.visibilityState='visible';visibility();await runTick();assert.equal(refreshes,1);done();await settle();const nextRefresh=runTick();assert.equal(refreshes,2);stop();done();await nextRefresh;await runTick();assert.equal(refreshes,2);assert.equal(visibility,null);

 // An old in-flight 401 must not clear a newer login in another browser tab.
 let finishFetch;const dispatched=[];const apiExports={};
 const apiCode=ts.transpileModule(fs.readFileSync(require('node:path').join(__dirname,'../src/services/api.ts'),'utf8').replace('import.meta.env.VITE_API_URL',JSON.stringify('/api')),{compilerOptions:{target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.CommonJS}}).outputText;
 new Function('exports','require','localStorage','window','Event','fetch',apiCode)(apiExports,()=>({getDeviceIdentity:()=>({deviceId:'test-device-12345',deviceName:'Test'})}),localStorage,{dispatchEvent:event=>dispatched.push(event.type),location:{}},class{constructor(type){this.type=type}},()=>new Promise(resolve=>finishFetch=resolve));
 storage.set('authToken','old-token');const oldRequest=apiExports.authFetch('/api/auth/me');storage.set('authToken','new-token');finishFetch({ok:false,status:401,statusText:'Unauthorized',text:async()=>JSON.stringify({code:'SESSION_REVOKED',error:'revoked'})});await assert.rejects(oldRequest);assert.equal(dispatched.length,0);assert.equal(storage.get('authToken'),'new-token');
 const currentRequest=apiExports.authFetch('/api/auth/me');finishFetch({ok:false,status:401,statusText:'Unauthorized',text:async()=>JSON.stringify({code:'SESSION_REVOKED',error:'revoked'})});await assert.rejects(currentRequest);assert.deepEqual(dispatched,['session-revoked']);
 console.log('PASS: browser identity shared across tabs and visibility-aware polling without overlapping requests');
})().catch(error=>{console.error(error);process.exitCode=1});
