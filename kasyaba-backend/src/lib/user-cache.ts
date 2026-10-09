/**
 * Small in-process caches for per-user derived data.
 *
 * `withUserResponseCache` collapses concurrent and repeated reads of expensive
 * user-scoped responses. `withUserThrottle` limits how often a background
 * recomputation runs for one user. Both are cleared by the app-level
 * middleware whenever the user performs a successful mutating request, so on
 * this instance a write is never followed by a stale read.
 *
 * Entries are intentionally short-lived: with more than one API replica, a
 * mutation handled by instance A cannot clear instance B, so the TTL bounds
 * cross-instance staleness.
 */
const RESPONSE_TTL_MS = 30_000;
const THROTTLE_TTL_MS = 30_000;

const responseCache = new Map<string, { expiresAt: number; value: unknown }>();
const inFlight = new Map<string, Promise<unknown>>();
const throttles = new Map<string, number>();

let lastPruneAt = 0;

/** Drops expired entries so long-running instances do not accumulate them. */
function pruneExpired(now: number): void {
  if (now - lastPruneAt < 60_000) return;
  lastPruneAt = now;
  for (const [key, entry] of responseCache) {
    if (entry.expiresAt <= now) responseCache.delete(key);
  }
  for (const [key, expiresAt] of throttles) {
    if (expiresAt <= now) throttles.delete(key);
  }
}

export async function withUserResponseCache<T>(
  key: string,
  build: () => Promise<T>,
): Promise<T> {
  const now = Date.now();
  pruneExpired(now);

  const cached = responseCache.get(key);
  if (cached && cached.expiresAt > now) return cached.value as T;

  const pending = inFlight.get(key);
  if (pending) return pending as Promise<T>;

  const promise = build()
    .then((value) => {
      responseCache.set(key, {
        expiresAt: Date.now() + RESPONSE_TTL_MS,
        value,
      });
      return value;
    })
    .finally(() => {
      inFlight.delete(key);
    });

  inFlight.set(key, promise);
  return promise;
}

/**
 * Runs `task` at most once per TTL window for `key`. Returns true when the
 * task ran, false when it was throttled. Failures clear the window so the
 * next request can retry immediately.
 */
export async function withUserThrottle(
  key: string,
  task: () => Promise<void>,
): Promise<boolean> {
  const now = Date.now();
  pruneExpired(now);

  const expiresAt = throttles.get(key);
  if (expiresAt && expiresAt > now) return false;

  throttles.set(key, now + THROTTLE_TTL_MS);
  try {
    await task();
    return true;
  } catch (err) {
    throttles.delete(key);
    throw err;
  }
}

/** Clears every cache entry that belongs to `userId`. */
export function invalidateUserCaches(userId: string): void {
  const suffix = `:${userId}`;
  for (const key of responseCache.keys()) {
    if (key.endsWith(suffix)) responseCache.delete(key);
  }
  for (const key of throttles.keys()) {
    if (key.endsWith(suffix)) throttles.delete(key);
  }
}
