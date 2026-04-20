export const GEMINI_ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent";

const animalValidationPrompt = `
Determine whether the provided image contains a real animal or animal artwork as a visible subject. Animals include pets, wildlife, birds, reptiles, fish, and farm animals. Reject inanimate objects, cups, desks, food, logos, landscapes with no animal, and people-only photos. Reply with exactly ANIMAL or NOT_ANIMAL.
`;

export async function validateAnimalImage(apiKey, imageData, mimeType) {
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

export async function generateGeminiImage(apiKey, prompt, imageData, mimeType, options = {}) {
  const generationConfig = {
    responseModalities: ["IMAGE"]
  };

  if (options.aspectRatio) {
    generationConfig.imageConfig = {
      aspectRatio: options.aspectRatio
    };
  }

  for (let attempt = 0; attempt < 2; attempt += 1) {
    const geminiResponse = await sendGeminiRequest(apiKey, {
      contents: [{
        parts: [
          { text: prompt },
          { inline_data: { mime_type: mimeType, data: imageData } }
        ]
      }],
      generationConfig
    });

    const imagePart = collectImagePart(geminiResponse);
    if (imagePart) {
      return imagePart;
    }
  }

  throw new Error("No image found in Gemini response");
}

export async function sendGeminiRequest(apiKey, body) {
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
