import { buildUsagePayload, currentMonthBucket } from "./_lib/usage.js";
import { generateGeminiImage, validateAnimalImage } from "./_lib/gemini.js";

export const config = {
  api: {
    bodyParser: {
      sizeLimit: "8mb"
    }
  },
  maxDuration: 60
};

export default async function handler(request, response) {
  response.setHeader("Access-Control-Allow-Origin", "*");
  response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  response.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (request.method === "OPTIONS") {
    response.status(204).end();
    return;
  }

  if (request.method !== "POST") {
    response.status(405).json({ error: "Method not allowed" });
    return;
  }

  const apiKey = process.env.GEMINI_API_KEY;
  if (!apiKey) {
    response.status(500).json({ error: "Gemini API key is not configured" });
    return;
  }

  const { imageData, mimeType } = request.body || {};
  if (!imageData || !mimeType) {
    response.status(400).json({ error: "Missing image data" });
    return;
  }

  try {
    await validateAnimalImage(apiKey, imageData, mimeType);

    const optimizedImage = await generateGeminiImage(
      apiKey,
      buildOptimizationPrompt(),
      imageData,
      mimeType
    );

    response.status(200).json({
      imageData: optimizedImage.data,
      mimeType: optimizedImage.mimeType || "image/png",
      usage: buildUsagePayload(0, currentMonthBucket()),
      optimized: true
    });
  } catch (error) {
    const status = error.status || 500;
    response.status(status).json({ error: error.message || "Optimization failed" });
  }
}

function buildOptimizationPrompt() {
  return [
    "Optimize the provided animal photo while preserving the exact same animal identity, species, markings, face, expression, pose, and overall scene.",
    "Improve image quality only: refine lighting, contrast, tonal balance, sharpness, clarity, and background cleanliness.",
    "Remove minor distractions, scratches, noise, and clutter when possible, but do not change the animal or invent new accessories, props, scenery, or style.",
    "Render it with the natural look of a 50mm lens.",
    "If there is a single clear subject, make it feel like it was photographed at f/2 with tasteful bokeh and subject separation.",
    "If there are multiple clear subjects, make it feel like it was photographed at f/5.6 on a 50mm lens so all primary subjects stay acceptably in focus.",
    "Keep the result photorealistic and natural, not artistic.",
    "Preserve the original framing and orientation as closely as possible.",
    "Return one optimized image only."
  ].join(" ");
}
