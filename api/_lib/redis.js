import { createClient } from "redis";

let clientPromise;

export async function getRedisClient() {
  if (!process.env.REDIS_URL) {
    throw new Error("Redis is not configured");
  }

  if (!clientPromise) {
    const client = createClient({ url: process.env.REDIS_URL });
    client.on("error", error => {
      console.error("Redis error", error);
    });
    clientPromise = client.connect().then(() => client);
  }

  return clientPromise;
}
