const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../src/controllers/aiController.js'), 'utf8')
    .replace(/^import .*;$/gm, '').replace('export const chatWithGemini', 'const chatWithGemini');
const env = { GEMINI_API_KEY: 'gemini-test', GROQ_API_KEY: 'groq-test', GROQ_MODEL: 'openai/gpt-oss-20b' };
const req = () => ({ user: { userId: 'test-user' }, body: {
    contents: [{ role: 'user', parts: [{ text: 'Plan Bangkok' }] }, { role: 'model', parts: [{ text: 'What budget?' }] }, { role: 'user', parts: [{ text: '500 THB' }] }]
} });
const res = () => ({ statusCode: 200, setHeader() {}, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } });
const failure = status => Object.assign(new Error('upstream'), { response: { status } });
const groq = text => ({ data: { choices: [{ message: { content: text }, finish_reason: 'stop' }] } });
function handler(post, configuration = env) {
    return new Function('axios', 'process', 'console', source + '\nreturn chatWithGemini;')(
        { post }, { env: configuration }, { warn() {} });
}
(async () => {
    let calls = [];
    const fallback = handler(async (url, body, config) => {
        calls.push(url);
        if (!url.includes('api.groq.com')) throw failure(429);
        assert.equal(config.headers.Authorization, 'Bearer groq-test');
        assert.equal(config.timeout, 15000);
        assert.equal(body.messages[1].role, 'assistant');
        return groq('เที่ยวกรุงเทพ');
    });
    const first = res(); await fallback(req(), first);
    assert.equal(first.body.candidates[0].content.parts[0].text, 'เที่ยวกรุงเทพ');
    const second = res(); await fallback(req(), second);
    assert.equal(second.statusCode, 200);
    assert.equal(calls.length, 3, 'Gemini cooldown should route the next request directly to Groq');

    const primary = handler(async url => {
        assert.ok(!url.includes('api.groq.com'));
        return { data: { candidates: [{ content: { parts: [{ text: 'Gemini result' }] } }] } };
    });
    const primaryResult = res(); await primary(req(), primaryResult);
    assert.equal(primaryResult.body.candidates[0].content.parts[0].text, 'Gemini result');

    let badCalls = 0;
    const badInput = handler(async () => { badCalls++; throw failure(400); });
    await badInput(req(), res());
    assert.equal(badCalls, 1, 'Do not retry provider validation errors with another provider');
    const malformed = req(); malformed.body.contents = [];
    const malformedResult = res(); await badInput(malformed, malformedResult);
    assert.equal(malformedResult.statusCode, 400);
    assert.equal(badCalls, 1);

    const json = handler(async (url, body) => {
        if (!url.includes('api.groq.com')) throw Object.assign(new Error('timeout'), { code: 'ECONNABORTED' });
        assert.equal(body.response_format.type, 'json_object');
        assert.equal(body.messages[0].role, 'system');
        return groq('{"title":"Bangkok"}');
    });
    const jsonReq = req(); jsonReq.body.generationConfig = { responseMimeType: 'application/json', maxOutputTokens: 99999 };
    const jsonResult = res(); await json(jsonReq, jsonResult);
    assert.equal(JSON.parse(jsonResult.body.candidates[0].content.parts[0].text).title, 'Bangkok');

    let recoveryCalls = 0;
    const recovery = handler(async (url, body, config) => {
        recoveryCalls++;
        if (recoveryCalls === 1) {
            assert.equal(config.timeout, 12000);
            throw Object.assign(new Error('timeout'), { code: 'ECONNABORTED' });
        }
        if (url.includes('api.groq.com')) throw failure(429);
        return { data: { candidates: [{ content: { parts: [{ text: 'primary recovered' }] } }] } };
    });
    const unavailable = res(); await recovery(req(), unavailable);
    assert.equal(unavailable.statusCode, 503);
    const recovered = res(); await recovery(req(), recovered);
    assert.equal(recovered.body.candidates[0].content.parts[0].text, 'primary recovered');
    assert.equal(recoveryCalls, 3, 'Groq cooldown must not disable recovered Gemini');

    const invalidJSON = handler(async url => {
        if (!url.includes('api.groq.com')) throw failure(503);
        return groq('not JSON');
    });
    const invalidResult = res(); await invalidJSON(jsonReq, invalidResult);
    assert.equal(invalidResult.statusCode, 503);

    let failCount = 0;
    const bothFail = handler(async () => { failCount++; throw failure(429); });
    const failed = res(); await bothFail(req(), failed);
    assert.equal(failed.statusCode, 503);
    await bothFail(req(), res());
    assert.equal(failCount, 2, 'Both providers in cooldown should not receive another request');

    let release;
    const pending = handler(async () => new Promise(resolve => { release = resolve; }));
    const request = pending(req(), res());
    const busy = res(); await pending(req(), busy);
    assert.equal(busy.body.code, 'AI_BUSY');
    release({ data: { candidates: [] } }); await request;

    const groqOnly = handler(async () => groq('fallback only'), { GROQ_API_KEY: 'groq-test' });
    const onlyResult = res(); await groqOnly(req(), onlyResult);
    assert.equal(onlyResult.statusCode, 200);
    console.log('PASS: primary, fallback, cooldown, timeout, JSON, validation, slot isolation and missing primary key');
})().catch(error => { console.error(error); process.exitCode = 1; });
