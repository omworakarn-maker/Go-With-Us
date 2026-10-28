// Host-side helper for UI tests: performs actions the simulator-side test cannot (DB edits, stopping/starting backend).
import { existsSync, rmSync, writeFileSync } from 'node:fs';
import { spawn, execSync } from 'node:child_process';
import bcrypt from '../backend-api/node_modules/bcryptjs/index.js';
import prisma from '../backend-api/src/utils/prismaClient.js';
const f = (n) => `/tmp/tc34-${n}`;
['expire-request','expire-done','stop-request','stop-done','start-request','start-done'].forEach((n) => rmSync(f(n), { force: true }));
const startBackend = () => spawn('node', ['src/index.js'], { cwd: new URL('../backend-api/', import.meta.url).pathname, stdio: ['ignore', 'ignore', 'ignore'], detached: true }).unref();
console.log('watcher running');
setInterval(async () => {
  if (existsSync(f('expire-request'))) {
    rmSync(f('expire-request'));
    await prisma.pendingRegistration.update({ where: { email: 'tc34_ui_otp@example.com' }, data: { otpCode: await bcrypt.hash('123456', 10), otpExpiresAt: new Date(Date.now() - 60000) } });
    writeFileSync(f('expire-done'), 'ok'); console.log('pending OTP set to 123456 + expired');
  }
  if (existsSync(f('stop-request'))) {
    rmSync(f('stop-request'));
    try { execSync("pkill -f 'node src/index.js'"); } catch {}
    writeFileSync(f('stop-done'), 'ok'); console.log('backend stopped');
  }
  if (existsSync(f('start-request'))) {
    rmSync(f('start-request')); startBackend();
    setTimeout(() => { writeFileSync(f('start-done'), 'ok'); console.log('backend restarted'); }, 6000);
  }
}, 500);
