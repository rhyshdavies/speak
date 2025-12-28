import { WebSocket, WebSocketServer } from 'ws';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { buildSystemPrompt } from '../../prompts/system-prompts.js';
import type { ScenarioContext, CEFRLevel } from '../../types/index.js';

// Configuration
const ELEVENLABS_API_KEY = process.env.ELEVEN_LABS_API_KEY!;
const GEMINI_API_KEY = process.env.GEMINI_API_KEY!;
const CARTESIA_API_KEY = process.env.CARTESIA_API_KEY!;

// Spanish voice for Cartesia Sonic-3
const CARTESIA_VOICE_ID = 'c0c374aa-09be-42d9-9828-4d2d7df86962';

interface SessionState {
  isPaused: boolean;
  speechRate: number;
  scenario: ScenarioContext | null;
  cefrLevel: CEFRLevel;
  conversationHistory: Array<{ role: string; content: string }>;
}

interface ClientMessage {
  type: 'config' | 'pause' | 'resume' | 'setup';
  speechRate?: number;
  scenario?: ScenarioContext;
  cefrLevel?: CEFRLevel;
}

export class RealtimeServer {
  private wss: WebSocketServer;
  private genAI: GoogleGenerativeAI;

  constructor(port: number = 8080) {
    this.wss = new WebSocketServer({ port });
    this.genAI = new GoogleGenerativeAI(GEMINI_API_KEY);
    this.setupServer();
    console.log(`🚀 Realtime WebSocket Server running on port ${port}`);
    console.log(`   Advanced Mode: Real-time streaming enabled`);
    console.log(`   STT: ElevenLabs Scribe v2 Realtime`);
  }

  private setupServer() {
    this.wss.on('connection', (clientSocket: WebSocket) => {
      console.log('[Realtime] Client connected');

      // Session state
      const state: SessionState = {
        isPaused: false,
        speechRate: 0.0,
        scenario: null,
        cefrLevel: 'A1',
        conversationHistory: [],
      };

      // Cartesia TTS WebSocket
      let cartesiaSocket: WebSocket | null = null;
      let cartesiaContextId = `ctx-${Date.now()}`;

      // ElevenLabs Scribe WebSocket
      let scribeSocket: WebSocket | null = null;
      let currentTranscript = '';

      const connectCartesia = () => {
        const cartesiaUrl = 'wss://api.cartesia.ai/tts/websocket';
        console.log('[Realtime] Connecting to Cartesia');
        cartesiaSocket = new WebSocket(cartesiaUrl, undefined, {
          headers: {
            'X-API-Key': CARTESIA_API_KEY,
            'Cartesia-Version': '2025-04-16',
          },
        });

        cartesiaSocket.on('open', () => {
          console.log('[Realtime] Cartesia TTS connected');
        });

        let firstTTSChunkTime: number | null = null;
        let ttsStartTime: number | null = null;

        cartesiaSocket.on('message', (data: Buffer) => {
          try {
            const response = JSON.parse(data.toString());
            if (response.type === 'chunk' && response.data) {
              if (!firstTTSChunkTime && ttsStartTime) {
                firstTTSChunkTime = Date.now();
                console.log(`[Realtime] ⏱️ First TTS chunk latency: ${firstTTSChunkTime - ttsStartTime}ms`);
              }
              clientSocket.send(
                JSON.stringify({
                  type: 'audio',
                  data: response.data,
                  context_id: response.context_id,
                })
              );
            } else if (response.type === 'done') {
              console.log('[Realtime] Cartesia done, sending audio_done to client');
              clientSocket.send(JSON.stringify({ type: 'audio_done' }));

              // Resume STT after TTS finishes (prevents hearing itself)
              state.isPaused = false;
              console.log('[Realtime] Resumed (TTS complete)');

              // Reconnect Scribe if it disconnected during TTS
              if (!scribeSocket || scribeSocket.readyState !== WebSocket.OPEN) {
                console.log('[Realtime] Scribe disconnected, reconnecting...');
                connectScribe();
              }
            } else if (response.type === 'error') {
              console.error('[Realtime] Cartesia error response:', response);
            }
          } catch (e) {
            clientSocket.send(data);
          }
        });

        cartesiaSocket.on('error', (err) => {
          console.error('[Realtime] Cartesia error:', err);
          cartesiaSocket = null;
        });

        cartesiaSocket.on('close', () => {
          console.log('[Realtime] Cartesia disconnected');
          cartesiaSocket = null;
        });
      };

      const sendToCartesia = (text: string, isContinue: boolean = true) => {
        if (!cartesiaSocket || cartesiaSocket.readyState !== WebSocket.OPEN) {
          return;
        }
        console.log(`[Realtime] Sending to Cartesia: "${text.substring(0, 50)}..." continue=${isContinue}`);

        const payload = {
          model_id: 'sonic-2024-10-19',
          transcript: text,
          voice: {
            mode: 'id',
            id: CARTESIA_VOICE_ID,
          },
          language: 'es',
          output_format: {
            container: 'raw',
            encoding: 'pcm_s16le',
            sample_rate: 24000,
          },
          context_id: cartesiaContextId,
          continue: isContinue,
        };
        cartesiaSocket.send(JSON.stringify(payload));
      };

      // Gemini LLM
      const processWithGemini = async (transcript: string) => {
        if (state.isPaused || !state.scenario) return;

        const startTime = Date.now();
        console.log(`[Realtime] User said: "${transcript}" (processing started)`);

        state.conversationHistory.push({ role: 'user', content: transcript });

        const systemPrompt = buildSystemPrompt(state.scenario, state.cefrLevel);

        const model = this.genAI.getGenerativeModel({
          model: 'gemini-2.0-flash-exp',
          generationConfig: {
            responseMimeType: 'application/json',
          },
        });

        const chat = model.startChat({
          history: [
            {
              role: 'user',
              parts: [{ text: systemPrompt }],
            },
            {
              role: 'model',
              parts: [
                {
                  text: 'Entendido. Responderé en JSON válido como tutor de español.',
                },
              ],
            },
            ...state.conversationHistory.map((m) => ({
              role: m.role === 'user' ? 'user' : ('model' as const),
              parts: [{ text: m.content }],
            })),
          ],
        });

        try {
          cartesiaContextId = `ctx-${Date.now()}`;
          state.isPaused = true;
          console.log('[Realtime] Paused STT (generating response)');

          const result = await chat.sendMessageStream(transcript);
          let fullResponse = '';
          let jsonBuffer = '';

          for await (const chunk of result.stream) {
            const chunkText = chunk.text();
            if (chunkText) {
              jsonBuffer += chunkText;

              // Match tutorSpanish including escaped characters
              const spanishMatch = jsonBuffer.match(
                /"tutorSpanish"\s*:\s*"((?:[^"\\]|\\.)*)"/
              );
              if (spanishMatch && spanishMatch[1] !== fullResponse) {
                const newText = spanishMatch[1].slice(fullResponse.length);
                if (newText) {
                  fullResponse = spanishMatch[1];
                  sendToCartesia(newText, true);

                  clientSocket.send(
                    JSON.stringify({
                      type: 'tutor_text',
                      text: newText,
                      fullText: fullResponse,
                    })
                  );
                }
              }
            }
          }

          if (fullResponse.length > 0) {
            sendToCartesia('', false);
          } else {
            // No tutorSpanish found - check if there's plain text response
            console.log('[Realtime] No JSON tutorSpanish found. Raw buffer:', jsonBuffer.substring(0, 500));

            // Try to use raw text as response (Gemini sometimes returns plain text)
            const cleanedText = jsonBuffer.trim()
              .replace(/^["']|["']$/g, '')  // Remove surrounding quotes
              .replace(/\\n/g, ' ')  // Replace newlines
              .trim();

            if (cleanedText.length > 5 && cleanedText.length < 500 && !cleanedText.includes('{')) {
              // Use the plain text response
              console.log('[Realtime] Using plain text response:', cleanedText);
              fullResponse = cleanedText;
              sendToCartesia(fullResponse, true);
              sendToCartesia('', false);

              // Create proper JSON structure with suggested responses
              const plainTextResponse = {
                tutorSpanish: fullResponse,
                tutorEnglish: '',  // Will be empty for plain text responses
                correctionSpanish: null,
                correctionEnglish: null,
                scenarioProgress: 'middle',
                suggestedResponses: ['Sí', 'No', '¿Por qué?'],  // Generic suggestions
              };
              jsonBuffer = JSON.stringify(plainTextResponse);

              clientSocket.send(
                JSON.stringify({
                  type: 'tutor_text',
                  text: fullResponse,
                  fullText: fullResponse,
                })
              );

              // Send tutor_response with suggestedResponses for the UI
              clientSocket.send(
                JSON.stringify({
                  type: 'tutor_response',
                  response: plainTextResponse,
                })
              );
            } else {
              // Generate fallback
              const fallbackResponse = '¿Puedes decir más? No entendí bien.';
              const fallbackEnglish = 'Can you say more? I did not understand well.';

              sendToCartesia(fallbackResponse, true);
              sendToCartesia('', false);

              fullResponse = fallbackResponse;
              jsonBuffer = JSON.stringify({
                tutorSpanish: fallbackResponse,
                tutorEnglish: fallbackEnglish,
                correctionSpanish: null,
                correctionEnglish: null,
                scenarioProgress: 'middle',
                suggestedResponses: ['Sí, claro', 'No, gracias', 'Otra vez, por favor'],
              });

              clientSocket.send(
                JSON.stringify({
                  type: 'tutor_text',
                  text: fallbackResponse,
                  fullText: fallbackResponse,
                })
              );
            }
          }

          let englishText = '';
          try {
            const parsed = JSON.parse(jsonBuffer);
            state.conversationHistory.push({
              role: 'assistant',
              content: parsed.tutorSpanish || fullResponse,
            });
            englishText = parsed.tutorEnglish || '';

            clientSocket.send(
              JSON.stringify({
                type: 'tutor_response',
                response: parsed,
              })
            );
            console.log(`[Realtime] Parsed JSON - English: "${englishText}"`);
          } catch (parseError) {
            const englishMatch = jsonBuffer.match(/"tutorEnglish"\s*:\s*"((?:[^"\\]|\\.)*)"/);  // Handle escaped chars
            englishText = englishMatch ? englishMatch[1] : '';

            console.log(`[Realtime] JSON parse failed, extracted English: "${englishText}"`);

            state.conversationHistory.push({
              role: 'assistant',
              content: fullResponse,
            });

            clientSocket.send(
              JSON.stringify({
                type: 'tutor_response',
                response: {
                  tutorSpanish: fullResponse,
                  tutorEnglish: englishText,
                  correctionSpanish: null,
                  correctionEnglish: null,
                  scenarioProgress: 'middle',
                  suggestedResponses: ['Sí', 'No', 'Repite, por favor'],
                },
              })
            );
          }

          const totalTime = Date.now() - startTime;
          console.log(`[Realtime] Tutor: "${fullResponse}" | English: "${englishText}"`);
          console.log(`[Realtime] ⏱️ LLM processing time: ${totalTime}ms`);
        } catch (error) {
          console.error('[Realtime] Gemini error:', error);
          clientSocket.send(
            JSON.stringify({
              type: 'error',
              message: 'Failed to generate response',
            })
          );
          // On error, resume STT so user can try again
          state.isPaused = false;
          console.log('[Realtime] Resumed (after error)');

          // Reconnect Scribe if needed
          if (!scribeSocket || scribeSocket.readyState !== WebSocket.OPEN) {
            console.log('[Realtime] Scribe disconnected, reconnecting...');
            connectScribe();
          }
        }
        // Note: On success, STT resumes when Cartesia sends 'done' event
        // This prevents the AI from hearing its own TTS output
      };

      // ElevenLabs Scribe STT
      const connectScribe = () => {
        const params = new URLSearchParams({
          model_id: 'scribe_v2_realtime',
          language_code: 'es',
          audio_format: 'pcm_16000',
          commit_strategy: 'vad',
          vad_silence_threshold_secs: '1.0',  // Commit after 1s of silence (balanced)
          vad_threshold: '0.3',  // Slightly higher to avoid false triggers
          min_speech_duration_ms: '100',  // Require 100ms of speech
          min_silence_duration_ms: '200',  // Need 200ms silence to end utterance
        });

        const scribeUrl = `wss://api.elevenlabs.io/v1/speech-to-text/realtime?${params.toString()}`;
        console.log('[Realtime] Connecting to ElevenLabs Scribe');

        scribeSocket = new WebSocket(scribeUrl, {
          headers: {
            'xi-api-key': ELEVENLABS_API_KEY,
          },
        });

        scribeSocket.on('open', () => {
          console.log('[Realtime] ElevenLabs Scribe STT connected');
          // Connect Cartesia after Scribe is ready
          try {
            connectCartesia();
          } catch (err) {
            console.error('[Realtime] Failed to connect Cartesia:', err);
          }
        });

        scribeSocket.on('message', (data: Buffer) => {
          try {
            const message = JSON.parse(data.toString());
            const msgType = message.message_type || message.type;

            if (msgType === 'session_started') {
              console.log('[Realtime] Scribe session started');
            } else if (msgType === 'partial_transcript') {
              const transcript = message.text || '';
              if (transcript) {
                currentTranscript = transcript;
                console.log(`[Realtime] Scribe partial: "${transcript}"`);
                clientSocket.send(
                  JSON.stringify({
                    type: 'transcript',
                    text: transcript,
                    isFinal: false,
                    speechFinal: false,
                  })
                );
              }
            } else if (msgType === 'committed_transcript') {
              const transcript = message.text || '';
              console.log(`[Realtime] Scribe committed: "${transcript}"`);

              if (transcript.trim().length > 0 && !state.isPaused) {
                clientSocket.send(
                  JSON.stringify({
                    type: 'transcript',
                    text: transcript,
                    isFinal: true,
                    speechFinal: true,
                  })
                );
                currentTranscript = '';
                processWithGemini(transcript.trim());
              }
            } else if (msgType === 'input_error' || msgType === 'error') {
              console.error('[Realtime] Scribe error:', message);
              clientSocket.send(
                JSON.stringify({
                  type: 'error',
                  message: `STT Error: ${message.error || message.message || 'Unknown error'}`,
                })
              );
            } else {
              console.log(`[Realtime] Scribe message: ${msgType}`, message);
            }
          } catch (e) {
            console.error('[Realtime] Error parsing Scribe message:', e);
          }
        });

        scribeSocket.on('error', (err) => {
          console.error('[Realtime] Scribe error:', err);
        });

        scribeSocket.on('close', (code, reason) => {
          console.log(`[Realtime] Scribe disconnected: ${code} ${reason}`);
          clientSocket.send(JSON.stringify({
            type: 'stt_disconnected',
            message: 'Speech recognition disconnected. Please restart the conversation.'
          }));
        });
      };

      // Connect to ElevenLabs Scribe when client connects
      connectScribe();

      // Handle messages from client
      clientSocket.on('message', (message: Buffer) => {
        try {
          // Try parsing as JSON (control message)
          const event = JSON.parse(message.toString()) as ClientMessage;

          switch (event.type) {
            case 'setup':
              if (event.scenario) state.scenario = event.scenario;
              if (event.cefrLevel) state.cefrLevel = event.cefrLevel;
              state.conversationHistory = [];
              console.log(
                `[Realtime] Setup: scenario=${state.scenario?.type}, level=${state.cefrLevel}`
              );
              clientSocket.send(JSON.stringify({ type: 'ready' }));
              break;

            case 'config':
              if (event.speechRate !== undefined) {
                state.speechRate = event.speechRate;
                console.log(`[Realtime] Speed: ${state.speechRate}`);
              }
              break;

            case 'pause':
              state.isPaused = true;
              if (cartesiaSocket?.readyState === WebSocket.OPEN) {
                cartesiaSocket.send(
                  JSON.stringify({
                    context_id: cartesiaContextId,
                    cancel: true,
                  })
                );
              }
              console.log('[Realtime] Paused');
              break;

            case 'resume':
              state.isPaused = false;
              console.log('[Realtime] Resumed');
              break;
          }
        } catch {
          // Binary audio data - send to ElevenLabs Scribe
          if (scribeSocket?.readyState === WebSocket.OPEN && !state.isPaused) {
            // Convert audio to base64 and send in ElevenLabs format
            const audioBase64 = message.toString('base64');
            scribeSocket.send(
              JSON.stringify({
                message_type: 'input_audio_chunk',
                audio_base_64: audioBase64,
                sample_rate: 16000,
                commit: false,
              })
            );
          }
        }
      });

      // Cleanup on disconnect
      clientSocket.on('close', () => {
        console.log('[Realtime] Client disconnected');
        scribeSocket?.close();
        cartesiaSocket?.close();
      });

      clientSocket.on('error', (err) => {
        console.error('[Realtime] Client error:', err);
      });
    });
  }

  public close() {
    this.wss.close();
  }
}
