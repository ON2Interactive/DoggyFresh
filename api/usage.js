import { fetchUsage } from "./_lib/usage.js";

export const config = {
  api: {
    bodyParser: false
  },
  maxDuration: 30
};

export default async function handler(request, response) {
  response.setHeader("Access-Control-Allow-Origin", "*");
  response.setHeader("Access-Control-Allow-Methods", "GET, OPTIONS");
  response.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (request.method === "OPTIONS") {
    response.status(204).end();
    return;
  }

  if (request.method !== "GET") {
    response.status(405).json({ error: "Method not allowed" });
    return;
  }

  try {
    const usage = await fetchUsage(request.query.deviceID);
    response.status(200).json({ usage });
  } catch (error) {
    response.status(error.status || 500).json({ error: error.message || "Usage lookup failed" });
  }
}
