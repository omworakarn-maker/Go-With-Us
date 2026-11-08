const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');

(async () => {
    const { createServerDiagnostics } = await import('../src/utils/serverDiagnostics.js');
    const logs = [];
    const logger = { info: (...args) => logs.push(args), warn: (...args) => logs.push(args) };
    const diagnostics = createServerDiagnostics({ logger, slowMs: 5 });
    const res = new EventEmitter();
    res.statusCode = 200;
    res.writableFinished = false;
    let next = 0;
    diagnostics.middleware({ path: '/api/users/private-id', method: 'GET',
        body: { password: 'secret' }, headers: { authorization: 'secret-token' } }, res, () => next++);
    assert.equal(next, 1);
    await new Promise(resolve => setTimeout(resolve, 15));
    assert(logs.some(([name]) => name === 'REQUEST_STALLED'));
    res.writableFinished = true;
    res.emit('finish');
    res.emit('close');
    diagnostics.sample();
    const metrics = logs.find(([name]) => name === 'SERVER_METRICS')[1];
    assert.equal(metrics.activeRequests, 0);
    assert.equal(metrics.completedRequests, 1);
    assert(Number.isFinite(metrics.rssMB));
    assert(!JSON.stringify(logs).includes('secret'));
    assert(!JSON.stringify(logs).includes('private-id'));
    const count = logs.length;
    diagnostics.middleware({ path: '/healthz' }, new EventEmitter(), () => next++);
    assert.equal(logs.length, count);
    diagnostics.start();
    diagnostics.start();
    assert.equal(logs.filter(([name]) => name === 'SERVER_DIAGNOSTICS_STARTED').length, 1);
    diagnostics.stop();
    console.log('PASS: stalled requests, cleanup, metrics, health bypass, and log privacy.');
})().catch(error => { console.error(error); process.exitCode = 1; });
