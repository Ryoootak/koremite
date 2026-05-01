import { MinutesResponse } from "./schema";

type CacheRecord = {
  expiresAt: number;
  value: MinutesResponse;
};

const memoryCache = new Map<string, CacheRecord>();

export async function readCached(sourceHash: string, ttlSeconds: number): Promise<MinutesResponse | null> {
  const now = Date.now();
  const memory = memoryCache.get(sourceHash);
  if (memory && memory.expiresAt > now) {
    return { ...memory.value, costInfo: { ...memory.value.costInfo, cacheHit: true } };
  }

  if (typeof caches === "undefined") return null;

  const cached = await workerCaches().default.match(cacheRequest(sourceHash));
  if (!cached) return null;

  const value = await cached.json() as MinutesResponse;
  memoryCache.set(sourceHash, { value, expiresAt: now + ttlSeconds * 1000 });
  return { ...value, costInfo: { ...value.costInfo, cacheHit: true } };
}

export async function writeCached(sourceHash: string, value: MinutesResponse, ttlSeconds: number): Promise<void> {
  const expiresAt = Date.now() + ttlSeconds * 1000;
  memoryCache.set(sourceHash, { value, expiresAt });

  if (typeof caches === "undefined") return;

  await workerCaches().default.put(
    cacheRequest(sourceHash),
    new Response(JSON.stringify(value), {
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        "Cache-Control": `max-age=${ttlSeconds}`
      }
    })
  );
}

function cacheRequest(sourceHash: string): Request {
  return new Request(`https://cache.koremite.local/minutes/${encodeURIComponent(sourceHash)}`);
}

function workerCaches(): { default: Cache } {
  return caches as unknown as { default: Cache };
}
