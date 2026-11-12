const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');

const source = fs.readFileSync(path.join(__dirname, '../src/controllers/aiController.js'), 'utf8')
    .replace(/^import .*;$/gm, '').replace('export const chatWithGemini', 'const chatWithGemini');
const request = { body: { contents: [{ role: 'user', parts: [{ text: 'test' }] }] }, user: { userId: 'u1' } };
const response = () => ({
    statusCode: 200, headers: {},
    setHeader(key, value) { this.headers[key] = value; },
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; }
});
function load(post) {
    return new Function('axios', 'process', 'console', `${source}\nreturn chatWithGemini;`)(
        { post }, { env: { GEMINI_API_KEY: 'test-key' } }, { warn() {} }
    );
}
(async () => {
    let calls = 0;
    const handler = load(async (_url, _body, config) => {
        calls += 1;
        assert.equal(config.timeout, 90000);
        if (calls === 1) throw Object.assign(new Error('timeout'), { code: 'ECONNABORTED' });
        return { data: { candidates: [] } };
    });
    const first = response();
    await handler(request, first);
    assert.equal(first.body.code, 'AI_TIMEOUT');
    const second = response();
    await handler(request, second);
    assert.equal(calls, 2, 'Timeout must release the user slot without a global cooldown');
    assert.equal(second.statusCode, 200);

    let rateLimitCalls = 0;
    const limited = load(async () => {
        rateLimitCalls += 1;
        throw { response: { status: 429 } };
    });
    await limited(request, response());
    const backoff = response();
    await limited(request, backoff);
    assert.equal(rateLimitCalls, 1, 'Provider rate limits must still trigger backoff');
    assert.equal(backoff.statusCode, 503);
    console.log('PASS: AI timeout budget, slot cleanup, recovery, and provider-rate-limit backoff.');
})().catch(error => { console.error(error); process.exitCode = 1; });
