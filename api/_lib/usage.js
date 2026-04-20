import { getRedisClient } from "./redis.js";

export const MONTHLY_LIMIT = 40;

export function normalizeDeviceID(deviceID) {
  if (typeof deviceID !== "string") {
    return "";
  }

  return deviceID.trim().toLowerCase();
}

export function currentMonthBucket() {
  const now = new Date();
  const year = now.getUTCFullYear();
  const month = String(now.getUTCMonth() + 1).padStart(2, "0");
  return `${year}-${month}`;
}

export function secondsUntilNextMonth() {
  const now = new Date();
  const nextMonth = Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1, 0, 0, 0);
  return Math.max(60, Math.ceil((nextMonth - now.getTime()) / 1000));
}

function usageKey(deviceID, monthBucket) {
  return `usage:${monthBucket}:${deviceID}`;
}

export async function fetchUsage(deviceID) {
  const normalizedID = normalizeDeviceID(deviceID);
  if (!normalizedID) {
    const error = new Error("Missing device ID");
    error.status = 400;
    throw error;
  }

  const redis = await getRedisClient();
  const monthBucket = currentMonthBucket();
  const used = Number(await redis.get(usageKey(normalizedID, monthBucket)) || 0);

  return buildUsagePayload(used, monthBucket);
}

export async function incrementUsage(deviceID) {
  const normalizedID = normalizeDeviceID(deviceID);
  if (!normalizedID) {
    const error = new Error("Missing device ID");
    error.status = 400;
    throw error;
  }

  const redis = await getRedisClient();
  const monthBucket = currentMonthBucket();
  const key = usageKey(normalizedID, monthBucket);

  const used = await redis.incr(key);
  if (used === 1) {
    await redis.expire(key, secondsUntilNextMonth());
  }

  return buildUsagePayload(Number(used), monthBucket);
}

export function buildUsagePayload(used, monthBucket) {
  return {
    used,
    limit: MONTHLY_LIMIT,
    remaining: Math.max(0, MONTHLY_LIMIT - used),
    monthBucket
  };
}
