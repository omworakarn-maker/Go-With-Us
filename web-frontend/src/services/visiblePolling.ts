// One outstanding refresh per caller, and no polling while this document is hidden.
export function startVisiblePolling(refresh: () => Promise<unknown>, interval: number) {
  let stopped = false;
  let pending = false;
  const run = async () => {
    if (stopped || pending || document.visibilityState !== 'visible') return;
    pending = true;
    try { await refresh(); } catch (error) { console.warn('Background refresh failed'); }
    finally { pending = false; }
  };
  void run();
  const timer = window.setInterval(run, interval);
  document.addEventListener('visibilitychange', run);
  return () => {
    stopped = true;
    window.clearInterval(timer);
    document.removeEventListener('visibilitychange', run);
  };
}
