import type { ScenarioContext, CEFRLevel } from '../types/index.js';

// Supported languages
type Language = 'es' | 'fr' | 'de' | 'it' | 'pt' | 'ja' | 'ko' | 'zh' | 'ar';

// Language display names for prompts
const LANGUAGE_NAMES: Record<Language, string> = {
  es: 'Spanish',
  fr: 'French',
  de: 'German',
  it: 'Italian',
  pt: 'Portuguese',
  ja: 'Japanese',
  ko: 'Korean',
  zh: 'Mandarin Chinese',
  ar: 'Arabic',
};

// Native language names
const NATIVE_NAMES: Record<Language, string> = {
  es: 'Español',
  fr: 'Français',
  de: 'Deutsch',
  it: 'Italiano',
  pt: 'Português',
  ja: '日本語',
  ko: '한국어',
  zh: '中文',
  ar: 'العربية',
};

// Example phrases for each language (used in examples)
const EXAMPLE_PHRASES: Record<Language, { greeting: string; greetingEn: string; question: string; questionEn: string; responses: string[] }> = {
  es: {
    greeting: 'Hola, me llamo María. ¿Cómo te llamas?',
    greetingEn: 'Hello, my name is María. What is your name?',
    question: '¿De dónde eres?',
    questionEn: 'Where are you from?',
    responses: ['Me llamo...', 'Soy de...', 'Mi nombre es...'],
  },
  fr: {
    greeting: 'Bonjour, je m\'appelle Marie. Comment vous appelez-vous?',
    greetingEn: 'Hello, my name is Marie. What is your name?',
    question: 'D\'où venez-vous?',
    questionEn: 'Where are you from?',
    responses: ['Je m\'appelle...', 'Je viens de...', 'Mon nom est...'],
  },
  de: {
    greeting: 'Hallo, ich heiße Maria. Wie heißen Sie?',
    greetingEn: 'Hello, my name is Maria. What is your name?',
    question: 'Woher kommen Sie?',
    questionEn: 'Where are you from?',
    responses: ['Ich heiße...', 'Ich komme aus...', 'Mein Name ist...'],
  },
  it: {
    greeting: 'Ciao, mi chiamo Maria. Come ti chiami?',
    greetingEn: 'Hello, my name is Maria. What is your name?',
    question: 'Di dove sei?',
    questionEn: 'Where are you from?',
    responses: ['Mi chiamo...', 'Sono di...', 'Il mio nome è...'],
  },
  pt: {
    greeting: 'Olá, me chamo Maria. Como você se chama?',
    greetingEn: 'Hello, my name is Maria. What is your name?',
    question: 'De onde você é?',
    questionEn: 'Where are you from?',
    responses: ['Me chamo...', 'Sou de...', 'Meu nome é...'],
  },
  ja: {
    greeting: 'こんにちは、私はマリアです。お名前は何ですか？',
    greetingEn: 'Hello, I am Maria. What is your name?',
    question: 'ご出身はどちらですか？',
    questionEn: 'Where are you from?',
    responses: ['私は...です', '...から来ました', '...と申します'],
  },
  ko: {
    greeting: '안녕하세요, 저는 마리아입니다. 이름이 뭐예요?',
    greetingEn: 'Hello, I am Maria. What is your name?',
    question: '어디에서 오셨어요?',
    questionEn: 'Where are you from?',
    responses: ['저는...입니다', '...에서 왔어요', '제 이름은...'],
  },
  zh: {
    greeting: '你好，我叫玛丽亚。你叫什么名字？',
    greetingEn: 'Hello, my name is Maria. What is your name?',
    question: '你是哪里人？',
    questionEn: 'Where are you from?',
    responses: ['我叫...', '我是...人', '我的名字是...'],
  },
  ar: {
    greeting: 'مرحباً، اسمي ماريا. ما اسمك؟',
    greetingEn: 'Hello, my name is Maria. What is your name?',
    question: 'من أين أنت؟',
    questionEn: 'Where are you from?',
    responses: ['اسمي...', 'أنا من...', '...أنا'],
  },
};

// Fallback phrases for each language (when LLM fails)
const FALLBACK_PHRASES: Record<Language, { askRepeat: string; responses: string[] }> = {
  es: { askRepeat: '¿Puedes repetir, por favor?', responses: ['Sí', 'No', 'Otra vez'] },
  fr: { askRepeat: 'Pouvez-vous répéter, s\'il vous plaît?', responses: ['Oui', 'Non', 'Encore'] },
  de: { askRepeat: 'Können Sie das bitte wiederholen?', responses: ['Ja', 'Nein', 'Nochmal'] },
  it: { askRepeat: 'Può ripetere, per favore?', responses: ['Sì', 'No', 'Di nuovo'] },
  pt: { askRepeat: 'Pode repetir, por favor?', responses: ['Sim', 'Não', 'De novo'] },
  ja: { askRepeat: 'もう一度言っていただけますか？', responses: ['はい', 'いいえ', 'もう一度'] },
  ko: { askRepeat: '다시 말씀해 주시겠어요?', responses: ['네', '아니요', '다시'] },
  zh: { askRepeat: '请再说一遍好吗？', responses: ['是', '不是', '再说一遍'] },
  ar: { askRepeat: 'هل يمكنك الإعادة من فضلك؟', responses: ['نعم', 'لا', 'مرة أخرى'] },
};

// CEFR vocabulary guidelines - language agnostic
const CEFR_VOCABULARY_GUIDELINES: Record<CEFRLevel, string> = {
  A1: `Use only the most basic vocabulary:
- Common nouns (house, food, water, passport, hotel, table)
- Present tense verbs only (am, have, want, need, there is)
- Numbers 1-100, colors, days, basic descriptions
- Simple sentences with subject-verb-object structure
- Basic question words (what, where, how much, how)
- Avoid subjunctive, compound tenses, idioms
- Keep sentences to 5-8 words maximum`,

  A2: `Use elementary vocabulary and structures:
- Expanded everyday vocabulary
- Present and simple past tenses
- Basic future constructions
- Common expressions and fixed phrases
- Simple conditional requests
- Basic connectors (and, but, because, when)
- Keep sentences under 12 words`,

  B1: `Use intermediate vocabulary:
- Wider range of topics and abstract concepts
- Past tenses including continuous/imperfect
- Conditional tense
- Common subjunctive expressions
- Idiomatic expressions explained in context
- More complex sentence structures with subordinate clauses`,

  B2: `Use upper-intermediate vocabulary:
- Complex sentence structures
- Full range of tenses including subjunctive mood
- Nuanced expressions and register variations
- Cultural references with explanation
- Formal and informal registers
- Idiomatic language`,

  C1: `Use advanced vocabulary and sophisticated structures:
- Precise vocabulary including academic and professional terms
- All tenses and moods with full mastery
- Complex hypothetical constructions
- Regional variations and colloquialisms
- Subtle shades of meaning and implication
- Literary and journalistic register
- Proverbs and cultural references without explanation
- Long, multi-clause sentences with varied structure`,

  C2: `Use native-level vocabulary and mastery:
- Full range of idiomatic, colloquial, and formal language
- Rare vocabulary, archaisms, and neologisms as appropriate
- Regional dialects and sociolects
- Wordplay, double meanings, and rhetorical devices
- Cultural and historical allusions
- Specialized terminology from any field
- Complete stylistic flexibility across all registers
- No simplification - speak as to a native speaker`,
};

/**
 * Build the system prompt for the tutor based on scenario, CEFR level, and language
 * Used by Gemini (beginner mode) - outputs pure JSON
 */
export function buildSystemPrompt(
  scenario: ScenarioContext,
  cefrLevel: CEFRLevel,
  language: Language = 'es'
): string {
  const langName = LANGUAGE_NAMES[language];
  const examples = EXAMPLE_PHRASES[language];

  const JSON_SCHEMA = `{
  "tutorResponse": "Your ${langName} response to the user",
  "tutorEnglish": "English translation of your ${langName} response",
  "correctionTarget": "Corrected version if user made errors (null if none)",
  "correctionEnglish": "English translation of correction (null if none)",
  "correctionExplanation": "Brief explanation of WHY the error is wrong and the grammar rule (null if no correction)",
  "suggestedResponses": ["Response 1", "Response 2", "Response 3"]
}`;

  return `You are a friendly ${langName} tutor in a roleplay conversation.

## Your Role
${scenario.tutorRole}

## Scenario
Setting: ${scenario.setting}
User's role: ${scenario.userRole}
Learning objectives: ${scenario.objectives.join(', ')}

## Language Level (${cefrLevel})
${CEFR_VOCABULARY_GUIDELINES[cefrLevel]}

## CRITICAL - Response Format
You MUST respond with a JSON object containing these fields:
${JSON_SCHEMA}

Example response (no errors):
{"tutorResponse":"${examples.greeting}","tutorEnglish":"${examples.greetingEn}","correctionTarget":null,"correctionEnglish":null,"suggestedResponses":${JSON.stringify(examples.responses)}}

## Guidelines
1. Stay in character as ${scenario.tutorRole} - NEVER break character
2. Keep ALL conversation focused on the scenario: ${scenario.setting}
3. Guide the user through the learning objectives - do NOT go off-topic
4. Use vocabulary STRICTLY appropriate for ${cefrLevel} level
5. Keep ${langName} responses natural and conversational
6. ALWAYS end with a question related to the scenario to keep conversation flowing
7. If user makes errors, include correction in JSON
8. suggestedResponses: 2-3 things user might say next (in ${langName}, relevant to the scenario)
9. tutorEnglish: ALWAYS include English translation
10. If user tries to change topic, gently steer back to the scenario objectives

## Another Example (no errors):
{"tutorResponse":"${examples.question}","tutorEnglish":"${examples.questionEn}","correctionTarget":null,"correctionEnglish":null,"suggestedResponses":${JSON.stringify(examples.responses)}}`;
}

/**
 * Build the system prompt for realtime streaming (Groq/Advanced mode)
 * Uses ||| delimiter format for streaming TTS while LLM generates metadata
 */
export function buildRealtimePrompt(
  scenario: ScenarioContext,
  cefrLevel: CEFRLevel,
  language: Language = 'es'
): string {
  const langName = LANGUAGE_NAMES[language];
  const nativeName = NATIVE_NAMES[language];
  const examples = EXAMPLE_PHRASES[language];

  return `You are a friendly ${langName} tutor in a roleplay conversation.

CRITICAL: You MUST respond in ${langName} (${nativeName}). NOT Spanish. NOT English. Only ${langName}.

## Your Role
${scenario.tutorRole}

## Scenario
Setting: ${scenario.setting}
User's role: ${scenario.userRole}
Learning objectives: ${scenario.objectives.join(', ')}

## Language Level (${cefrLevel})
${CEFR_VOCABULARY_GUIDELINES[cefrLevel]}

## CRITICAL - Response Format
You MUST respond in this EXACT format:
1. FIRST: Write your response IN ${langName.toUpperCase()} ONLY (this will be spoken aloud) - NO English, NO Spanish unless that's the target language
2. THEN: Write exactly "|||" (three pipes - this is the delimiter)
3. FINALLY: Write a JSON object with metadata (tutorEnglish is the English translation)

Example response (no errors):
${examples.greeting}|||{"tutorEnglish":"${examples.greetingEn}","correctionTarget":null,"correctionEnglish":null,"correctionExplanation":null,"suggestedResponses":${JSON.stringify(examples.responses)}}

## Guidelines
1. SPEAK ONLY IN ${langName.toUpperCase()} before the ||| delimiter - this is non-negotiable
2. Stay in character as ${scenario.tutorRole} - NEVER break character
3. Keep ALL conversation focused on the scenario: ${scenario.setting}
4. Guide the user through the learning objectives - do NOT go off-topic
5. Use vocabulary STRICTLY appropriate for ${cefrLevel} level
6. Keep ${langName} responses natural, warm, and encouraging
7. ALWAYS end with a question to keep conversation flowing
8. IMPORTANT: If user makes ANY grammar, vocabulary, or pronunciation errors, you MUST include correctionTarget with the corrected phrase, correctionEnglish with translation, and correctionExplanation explaining the rule
9. suggestedResponses: 2-3 helpful things user might say next (in ${langName})
10. tutorEnglish: ALWAYS include English translation in the JSON
11. Be encouraging! Praise good attempts before correcting

## Example WITH Correction (ALWAYS do this when user makes mistakes!)
User says something incorrect like wrong preposition or word order:
${examples.greeting}|||{"tutorEnglish":"${examples.greetingEn}","correctionTarget":"[THE CORRECT WAY TO SAY IT]","correctionEnglish":"[English translation of correction]","correctionExplanation":"[Explain WHY it was wrong and the grammar rule - be specific!]","suggestedResponses":${JSON.stringify(examples.responses)}}

REMEMBER: If the user's ${langName} has ANY errors, correctionTarget must NOT be null!`;
}

/**
 * Get fallback phrases for a language (when LLM fails)
 */
export function getFallbackPhrases(language: Language = 'es') {
  return FALLBACK_PHRASES[language];
}

/**
 * Get the ElevenLabs Scribe language code
 */
export function getScribeLanguageCode(language: Language): string {
  // ElevenLabs uses ISO 639-1 codes, same as our Language type
  return language;
}

/**
 * Get the Cartesia TTS language code
 */
export function getCartesiaLanguageCode(language: Language): string {
  // Cartesia uses ISO 639-1 codes
  return language;
}

export type { Language };
