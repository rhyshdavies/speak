// CEFR Proficiency Levels
export type CEFRLevel = 'A1' | 'A2' | 'B1' | 'B2';

// Scenario types for structured learning
export type ScenarioType =
  | 'airport'
  | 'restaurant'
  | 'greetings'
  | 'hotel'
  | 'shopping';

// Chat message structure
export interface ChatMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
  timestamp?: string;
}

// Scenario context passed with each turn
export interface ScenarioContext {
  type: ScenarioType;
  title: string;
  description: string;
  setting: string;
  userRole: string;
  tutorRole: string;
  objectives: string[];
}

// Vocabulary spotlight in tutor response
export interface VocabularySpotlight {
  word: string;
  translation: string;
  usage: string;
}

// Scenario progress tracking
export type ScenarioProgress = 'beginning' | 'middle' | 'ending' | 'complete';

// Structured JSON response from GPT-4o-mini
export interface TutorResponseJSON {
  tutorSpanish: string;           // Spanish response text
  tutorEnglish: string;           // English translation
  correctionSpanish?: string;     // User's corrected phrase (if needed)
  correctionEnglish?: string;     // English translation of correction
  hint?: string;                  // Contextual hint for user
  vocabularySpotlight?: VocabularySpotlight;
  scenarioProgress: ScenarioProgress;
  suggestedResponses?: string[];  // 2-3 suggested user replies
}

// Full turn response
export interface TurnResponse {
  userTranscript: string;         // What the user said (from Whisper)
  tutorResponse: TutorResponseJSON;
  audioBase64: string;            // Base64-encoded WAV audio
  audioMimeType: string;
}

// Request body for conversation turn
export interface ConversationTurnRequest {
  messages: ChatMessage[];
  scenario: ScenarioContext;
  cefrLevel: CEFRLevel;
  playbackSpeed?: number;         // 0.75 | 1.0 | 1.25
}

// API Error response
export interface APIError {
  error: string;
  details?: string;
}
