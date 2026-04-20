import { generateGeminiImage, validateAnimalImage } from "./_lib/gemini.js";
import { MONTHLY_LIMIT, fetchUsage, incrementUsage } from "./_lib/usage.js";

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

  const { imageData, mimeType, styleDescription, dogContext, customInstruction, deviceID } = request.body || {};
  if (!imageData || !mimeType || !styleDescription) {
    response.status(400).json({ error: "Missing image or style data" });
    return;
  }

  try {
    const usage = await fetchUsage(deviceID);
    if (usage.used >= MONTHLY_LIMIT) {
      response.status(429).json({
        error: "Monthly generation limit reached.",
        usage
      });
      return;
    }

    await validateAnimalImage(apiKey, imageData, mimeType);
    const generatedImage = await generateImage({
      apiKey,
      imageData,
      mimeType,
      styleDescription,
      dogContext: dogContext || {},
      customInstruction
    });
    const updatedUsage = await incrementUsage(deviceID);

    response.status(200).json({
      imageData: generatedImage.data,
      mimeType: generatedImage.mimeType || "image/png",
      usage: updatedUsage
    });
  } catch (error) {
    const status = error.status || 500;
    response.status(status).json({ error: error.message || "Generation failed" });
  }
}

async function generateImage(payload) {
  const prompt = buildPrompt(payload.styleDescription, payload.dogContext, payload.customInstruction);
  return generateGeminiImage(payload.apiKey, prompt, payload.imageData, payload.mimeType, {
    aspectRatio: "1:1"
  });
}

function buildPrompt(styleDescription, dogContext = {}, customInstruction) {
  let prompt = `Create a single premium cinematic portrait from the provided animal photo in ${styleDescription}. Preserve the exact same animal identity, species, face structure, markings, fur color, proportions, and core expression from the source image. Keep the result realistic, editorial, polished, and visually striking. Avoid cartoon styling unless explicitly requested, avoid distorted anatomy, duplicate animals, extra limbs, extra heads, text, watermark, cluttered props, messy costume styling, and cheap-looking backgrounds.`;

  if (dogContext.name) {
    prompt += ` This is ${dogContext.name}`;
    if (dogContext.gender) {
      prompt += `, a ${String(dogContext.gender).toLowerCase()}`;
      if (dogContext.color) {
        prompt += ` ${dogContext.color} animal`;
      }
    } else if (dogContext.color) {
      prompt += `, a ${dogContext.color} animal`;
    }
    prompt += ".";
  }

  const instruction = typeof customInstruction === "string" ? customInstruction.trim() : "";
  if (instruction) {
    prompt += ` Apply this user direction: ${instruction}.`;
  }

  prompt += " Keep the animal instantly recognizable and make it look exceptional. Generate the final image as a square 1:1 composition. Return one generated image only, with no text-only response.";
  return prompt;
}
