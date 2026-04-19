const GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent";

const animalValidationPrompt = `
Determine whether the provided image contains a real animal or animal artwork as a visible subject. Animals include pets, wildlife, birds, reptiles, fish, and farm animals. Reject inanimate objects, cups, desks, food, logos, landscapes with no animal, and people-only photos. Reply with exactly ANIMAL or NOT_ANIMAL.
`;

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

  const { imageData, mimeType, styleDescription, dogContext, customInstruction } = request.body || {};
  if (!imageData || !mimeType || !styleDescription) {
    response.status(400).json({ error: "Missing image or style data" });
    return;
  }

  try {
    await validateAnimalImage(apiKey, imageData, mimeType);
    const generatedImage = await generateImage(apiKey, {
      imageData,
      mimeType,
      styleDescription,
      dogContext: dogContext || {},
      customInstruction
    });

    response.status(200).json({
      imageData: generatedImage.data,
      mimeType: generatedImage.mimeType || "image/png"
    });
  } catch (error) {
    const status = error.status || 500;
    response.status(status).json({ error: error.message || "Generation failed" });
  }
}

async function validateAnimalImage(apiKey, imageData, mimeType) {
  const geminiResponse = await sendGeminiRequest(apiKey, {
    contents: [{
      parts: [
        { text: animalValidationPrompt },
        { inline_data: { mime_type: mimeType, data: imageData } }
      ]
    }],
    generationConfig: {
      responseModalities: ["TEXT"]
    }
  });

  const text = collectText(geminiResponse).toUpperCase();
  if (!text.includes("ANIMAL") || text.includes("NOT_ANIMAL")) {
    const error = new Error("Please use an animal photo.");
    error.status = 422;
    throw error;
  }
}

async function generateImage(apiKey, payload) {
  const prompt = buildPrompt(payload.styleDescription, payload.dogContext, payload.customInstruction);

  for (let attempt = 0; attempt < 2; attempt += 1) {
    const geminiResponse = await sendGeminiRequest(apiKey, {
      contents: [{
        parts: [
          { text: prompt },
          { inline_data: { mime_type: payload.mimeType, data: payload.imageData } }
        ]
      }],
      generationConfig: {
        responseModalities: ["IMAGE"],
        imageConfig: {
          aspectRatio: "1:1"
        }
      }
    });

    const imagePart = collectImagePart(geminiResponse);
    if (imagePart) {
      return imagePart;
    }
  }

  throw new Error("No image found in Gemini response");
}

async function sendGeminiRequest(apiKey, body) {
  const geminiResponse = await fetch(`${GEMINI_ENDPOINT}?key=${encodeURIComponent(apiKey)}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(body)
  });

  const json = await geminiResponse.json().catch(() => ({}));
  if (!geminiResponse.ok) {
    const error = new Error(json?.error?.message || `Gemini request failed (${geminiResponse.status})`);
    error.status = geminiResponse.status;
    throw error;
  }

  return json;
}

function buildPrompt(styleDescription, dogContext = {}, customInstruction) {
  let prompt = `Using the provided animal photo, create a new artistic image in ${styleDescription}. Preserve the actual animal species shown in the source image.`;

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

  prompt += " Keep the pet recognizable and make it look great. Generate the final image as a square 1:1 composition. Return one generated image only, with no text-only response.";
  return prompt;
}

function collectText(geminiResponse) {
  return (geminiResponse.candidates || [])
    .flatMap(candidate => candidate?.content?.parts || [])
    .map(part => part.text || "")
    .join(" ");
}

function collectImagePart(geminiResponse) {
  const parts = (geminiResponse.candidates || []).flatMap(candidate => candidate?.content?.parts || []);
  for (const part of parts) {
    const inlineData = part.inlineData || part.inline_data;
    if (inlineData?.data) {
      return {
        data: inlineData.data,
        mimeType: inlineData.mimeType || inlineData.mime_type
      };
    }
  }
  return null;
}
