import { monitorEventLoopDelay } from 'node:perf_hooks';

// No bodies, query strings, tokens, account IDs, or database URLs are logged.
export function createServerDiagnostics({ logger = console, slowMs = 15_000, intervalMs = 30_000 } = {}) {
    let activeRequests = 0;
    let completedRequests = 0;
    let sequence = 0;
    let timer;
    let cpu = process.cpuUsage();
    let lastTick = Date.now();
    const lag = monitorEventLoopDelay({ resolution: 20 });
    const mb = bytes => Math.round(bytes / 1024 / 1024);
    const groups = new Set(['auth', 'trips', 'messages', 'users', 'notifications', 'match', 'ai']);

    function middleware(req, res, next) {
        if (req.path === '/healthz') return next();
        const firstSegment = (req.path || '').split('/')[2];
        const group = groups.has(firstSegment) ? `/api/${firstSegment}` : 'other';
        const id = ++sequence;
        const started = Date.now();
        activeRequests += 1;
        let settled = false;
        const slow = setTimeout(() => {
            logger.warn('REQUEST_STALLED', { id, method: req.method, group,
                elapsedMs: Date.now() - started, activeRequests });
        }, slowMs);
        slow.unref?.();
        const done = () => {
            if (settled) return;
            settled = true;
            clearTimeout(slow);
            res.removeListener('finish', done);
            res.removeListener('close', done);
            activeRequests -= 1;
            completedRequests += 1;
            const elapsedMs = Date.now() - started;
            if (elapsedMs >= slowMs || !res.writableFinished || res.statusCode >= 500) {
                logger.warn('REQUEST_FINISHED', { id, method: req.method, group,
                    elapsedMs, status: res.statusCode, aborted: !res.writableFinished, activeRequests });
            }
        };
        res.once('finish', done);
        res.once('close', done);
        next();
    }

    function sample() {
        const now = Date.now();
        const memory = process.memoryUsage();
        const elapsedMs = Math.max(1, now - lastTick);
        const currentCPU = process.cpuUsage();
        const cpuPercent = Math.round(((currentCPU.user - cpu.user) + (currentCPU.system - cpu.system)) / (elapsedMs * 10));
        logger.info('SERVER_METRICS', {
            uptimeSeconds: Math.floor(process.uptime()), rssMB: mb(memory.rss),
            heapUsedMB: mb(memory.heapUsed), externalMB: mb(memory.external),
            cpuPercent, activeRequests, completedRequests,
            eventLoopMaxMs: Math.round(lag.max / 1e6),
            timerDelayMs: Math.max(0, elapsedMs - intervalMs)
        });
        cpu = currentCPU;
        lastTick = now;
        lag.reset();
    }

    return {
        middleware,
        start() {
            if (timer) return;
            lastTick = Date.now();
            cpu = process.cpuUsage();
            lag.enable();
            timer = setInterval(sample, intervalMs);
            timer.unref();
            logger.info('SERVER_DIAGNOSTICS_STARTED', { intervalMs, slowMs });
        },
        stop() {
            clearInterval(timer);
            timer = undefined;
            lag.disable();
        },
        sample
    };
}
