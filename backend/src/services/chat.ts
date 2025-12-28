import { GoogleGenerativeAI } from '@google/generative-ai';
import { buildSystemPrompt } from '../prompts/system-prompts.js';
import type {
  ChatMessage,
  ScenarioContext,
  CEFRLevel,
  TutorResponseJSON,
} from '../types/index.js';

// Initialize Gemini client
let genAI: GoogleGenerativeAI | null = null;

function getGeminiClient(): GoogleGenerativeAI {
  if (!genAI) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY environment variable is not set');
    }
    genAI = new GoogleGenerativeAI(apiKey);
  }
  return genAI;
}

/**
 * Generate tutor response using Gemini 2.5 Flash-Lite with structured JSON output
 * @param messages - Conversation history
 * @param scenario - Current scenario context
 * @param cefrLevel - User's CEFR proficiency level
 * @param userTranscript - What the user just said (transcribed)
 * @returns Structured tutor response
 */
export async function generateTutorResponse(
  messages: ChatMessage[],
  scenario: ScenarioContext,
  cefrLevel: CEFRLevel,
  userTranscript: string
): Promise<TutorResponseJSON> {
  const client = getGeminiClient();
  const model = client.getGenerativeModel({
    model: 'gemini-2.5-flash-lite-preview-09-2025',
    generationConfig: {
      responseMimeType: 'application/json',
      maxOutputTokens: 500,
    },
  });

  const systemPrompt = buildSystemPrompt(scenario, cefrLevel);

  // Build conversation history as a single prompt
  const historyText = messages
    .map((m) => `${m.role === 'user' ? 'User' : 'Tutor'}: ${m.content}`)
    .join('\n');

  const fullPrompt = `${systemPrompt}

## Conversation so far:
${historyText}

## User just said:
${userTranscript}

Respond with valid JSON only:`;

  try {
    const result = await model.generateContent(fullPrompt);
    const content = result.response.text();

    if (!content) {
      console.warn('[Chat] Empty response from Gemini, using fallback');
      return getFallbackResponse();
    }

    try {
      return JSON.parse(content) as TutorResponseJSON;
    } catch (e) {
      console.error('[Chat] Failed to parse JSON:', content);
      return getFallbackResponse();
    }
  } catch (error) {
    console.error('[Chat] Gemini API error:', error);
    return getFallbackResponse();
  }
}

function getFallbackResponse(): TutorResponseJSON {
  return {
    tutorSpanish: '¿Puedes repetir, por favor?',
    tutorEnglish: 'Can you repeat, please?',
    correctionSpanish: undefined,
    correctionEnglish: undefined,
    hint: undefined,
    vocabularySpotlight: undefined,
    scenarioProgress: 'middle',
    suggestedResponses: ['Sí, claro', 'Un momento'],
  };
}
