import { WebSocket, WebSocketServer } from 'ws';
import Groq from 'groq-sdk';
import { buildSystemPrompt } from '../../prompts/system-prompts.js';
import type { ScenarioContext, CEFRLevel } from '../../types/index.js';

// Configuration
const ELEVENLABS_API_KEY = process.env.ELEVEN_LABS_API_KEY!;
const GROQ_API_KEY = process.env.GROQ_API_KEY!;
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
  private groq: Groq;

  constructor(port: number = 8080) {
    // Bind to 0.0.0.0 for IPv4 (required for iOS devices)
    this.wss = new WebSocketServer({ port, host: '0.0.0.0' });
    this.groq = new Groq({ apiKey: GROQ_API_KEY });
    this.setupServer();
    console.log(`🚀 Realtime WebSocket Server running on port ${port}`);
    console.log(`   Advanced Mode: Real-time streaming enabled`);
    console.log(`   STT: ElevenLabs Scribe v2 Realtime`);
    console.log(`   LLM: Groq Llama 3.3 70B`);
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
      let ttsStartTime: number | null = null;
      let firstTTSChunkTime: number | null = null;

      // ElevenLabs Scribe WebSocket
      let scribeSocket: WebSocket | null = null;
      let currentTranscript = '';
      let scribeConnecting = false;  // Track if connection is in progress
      let pendingAudioChunks: Buffer[] = [];  // Buffer audio during reconnection

      let cartesiaRetryCount = 0;
      const MAX_CARTESIA_RETRIES = 3;

      const connectCartesia = () => {
        if (cartesiaRetryCount >= MAX_CARTESIA_RETRIES) {
          console.log('[Realtime] Cartesia max retries reached, waiting before retry...');
          return;
        }

        const cartesiaUrl = 'wss://api.cartesia.ai/tts/websocket';
        console.log('[Realtime] Connecting to Cartesia (attempt ' + (cartesiaRetryCount + 1) + ')');
        cartesiaSocket = new WebSocket(cartesiaUrl, undefined, {
          headers: {
            'X-API-Key': CARTESIA_API_KEY,
            'Cartesia-Version': '2025-04-16',
          },
        });

        cartesiaSocket.on('open', () => {
          console.log('[Realtime] Cartesia TTS connected');
          cartesiaRetryCount = 0;  // Reset on successful connection
        });

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
              pendingContexts--;
              console.log(`[Realtime] TTS context done, ${pendingContexts} remaining`);

              // Only signal complete when ALL contexts are done
              if (pendingContexts <= 0) {
                pendingContexts = 0;
                if (ttsStartTime) {
                  const ttsTotalTime = Date.now() - ttsStartTime;
                  console.log(`[Realtime] ⏱️ TTS total time: ${ttsTotalTime}ms`);
                }
                console.log('[Realtime] All TTS done, sending audio_done to client');
                clientSocket.send(JSON.stringify({ type: 'audio_done' }));

                // Reset TTS timing for next turn
                ttsStartTime = null;
                firstTTSChunkTime = null;

                // Resume STT after TTS finishes (prevents hearing itself)
                state.isPaused = false;
                console.log('[Realtime] Resumed (TTS complete)');

                // Proactively reconnect Scribe if it disconnected during long TTS
                // This reduces latency - connection starts before user speaks
                if (!scribeSocket || scribeSocket.readyState !== WebSocket.OPEN) {
                  console.log('[Realtime] Proactively reconnecting Scribe after TTS');
                  connectScribe();
                }
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
          cartesiaRetryCount++;
          // Retry with backoff after error (but not for rate limits)
          if (err.message?.includes('429')) {
            console.log('[Realtime] Cartesia rate limited - wait before retrying');
          } else if (cartesiaRetryCount < MAX_CARTESIA_RETRIES) {
            setTimeout(() => connectCartesia(), 1000 * cartesiaRetryCount);
          }
        });

        cartesiaSocket.on('close', () => {
          console.log('[Realtime] Cartesia disconnected');
          cartesiaSocket = null;
        });
      };

      let pendingContexts = 0;  // Track how many TTS contexts are in flight

      const sendToCartesia = (text: string) => {
        if (!cartesiaSocket || cartesiaSocket.readyState !== WebSocket.OPEN || !text.trim()) {
          return;
        }
        // Track TTS start time for first chunk latency
        if (!ttsStartTime) {
          ttsStartTime = Date.now();
        }

        // Each sentence gets unique context ID - plays immediately without blocking
        const contextId = `ctx-${Date.now()}-${Math.random().toString(36).substring(2, 8)}`;
        pendingContexts++;
        console.log(`[Realtime] TTS[${pendingContexts}]: "${text.substring(0, 40)}..." ctx=${contextId.substring(4, 15)}`);

        const payload = {
          model_id: 'sonic-3',
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
          context_id: contextId,
          continue: false,  // Each sentence is complete - play immediately
        };
        cartesiaSocket.send(JSON.stringify(payload));
      };

      // Groq LLM (Llama 3.3 70B)
      const processWithLLM = async (transcript: string) => {
        if (state.isPaused || !state.scenario) return;

        const startTime = Date.now();
        console.log(`[Realtime] User said: "${transcript}" (processing started)`);
        console.log(`[Realtime] Conversation history has ${state.conversationHistory.length} messages`);

        const systemPrompt = buildSystemPrompt(state.scenario, state.cefrLevel);

        // Build messages for Groq (OpenAI-compatible format)
        const messages: Array<{ role: 'system' | 'user' | 'assistant'; content: string }> = [
          { role: 'system', content: systemPrompt },
          ...state.conversationHistory.map((m) => ({
            role: (m.role === 'user' ? 'user' : 'assistant') as 'user' | 'assistant',
            content: m.content,
          })),
          { role: 'user', content: transcript },
        ];

        // Add user message to history
        state.conversationHistory.push({ role: 'user', content: transcript });

        try {
          cartesiaContextId = `ctx-${Date.now()}`;
          state.isPaused = true;
          console.log('[Realtime] Paused STT (generating response)');

          const stream = await this.groq.chat.completions.create({
            model: 'llama-3.3-70b-versatile',
            messages,
            temperature: 0.7,
            max_completion_tokens: 1024,
            stream: true,
          });

          let fullResponse = '';  // Spanish text (before |||)
          let jsonBuffer = '';    // JSON metadata (after |||)
          let hitDelimiter = false;
          let pendingText = '';   // Buffer for partial chunks
          let sentenceCount = 0;
          let chunkCount = 0;
          let firstChunkTime: number | null = null;
          const streamStartTime = Date.now();

          for await (const chunk of stream) {
            const chunkText = chunk.choices[0]?.delta?.content || '';
            if (!chunkText) continue;

            chunkCount++;
            if (!firstChunkTime) {
              firstChunkTime = Date.now();
              console.log(`[Realtime] ⏱️ First Groq chunk at ${firstChunkTime - streamStartTime}ms: "${chunkText}"`);
            }

            // Log every 5th chunk to see streaming pattern
            if (chunkCount % 5 === 0 || chunkText.length > 20) {
              console.log(`[Realtime] Chunk #${chunkCount} at ${Date.now() - streamStartTime}ms: "${chunkText.substring(0, 30)}..."`);
            }

            if (!hitDelimiter) {
              // Collect Spanish text until we hit the delimiter
              pendingText += chunkText;

              const delimiterIndex = pendingText.indexOf('|||');
              if (delimiterIndex !== -1) {
                // Got all Spanish text - send to TTS in one request
                fullResponse = pendingText.substring(0, delimiterIndex).trim();
                console.log(`[Realtime] Hit delimiter at ${Date.now() - streamStartTime}ms, sending to TTS: "${fullResponse.substring(0, 50)}..."`);

                // Single TTS request - avoids rate limits, Cartesia still streams audio back
                sendToCartesia(fullResponse);

                // Send text to client
                clientSocket.send(JSON.stringify({
                  type: 'tutor_text',
                  text: fullResponse,
                  fullText: fullResponse,
                }));

                jsonBuffer = pendingText.substring(delimiterIndex + 3);
                hitDelimiter = true;
              }
            } else {
              // After delimiter - collect JSON
              jsonBuffer += chunkText;
            }
          }

          // Send any remaining pending text (partial sentence at end)
          if (pendingText && pendingText.trim() && !hitDelimiter) {
            fullResponse += pendingText;
            sendToCartesia(pendingText);
            clientSocket.send(JSON.stringify({
              type: 'tutor_text',
              text: pendingText,
              fullText: fullResponse,
            }));
          }

          // Fallback if no Spanish text was generated
          if (fullResponse.trim().length === 0) {
            const fallbackResponse = '¿Puedes repetir, por favor?';
            fullResponse = fallbackResponse;
            sendToCartesia(fallbackResponse);
            jsonBuffer = '{"tutorEnglish":"Can you repeat, please?","correctionSpanish":null,"correctionEnglish":null,"suggestedResponses":["Sí","No","Otra vez"]}';
            clientSocket.send(JSON.stringify({
              type: 'tutor_text',
              text: fallbackResponse,
              fullText: fallbackResponse,
            }));
          }

          // Add assistant response to history
          state.conversationHistory.push({
            role: 'assistant',
            content: fullResponse,
          });

          // Parse JSON metadata
          let englishText = '';
          let response: any = {
            tutorSpanish: fullResponse,
            tutorEnglish: '',
            correctionSpanish: null,
            correctionEnglish: null,
            suggestedResponses: ['Sí', 'No', '¿Por qué?'],
          };

          try {
            const parsed = JSON.parse(jsonBuffer.trim());
            englishText = parsed.tutorEnglish || '';
            response = {
              tutorSpanish: fullResponse,
              tutorEnglish: englishText,
              correctionSpanish: parsed.correctionSpanish || null,
              correctionEnglish: parsed.correctionEnglish || null,
              suggestedResponses: parsed.suggestedResponses || ['Sí', 'No', '¿Por qué?'],
            };
            console.log(`[Realtime] Parsed JSON - English: "${englishText}"`);
          } catch (parseError) {
            // Try to extract English with regex
            const englishMatch = jsonBuffer.match(/"tutorEnglish"\s*:\s*"((?:[^"\\]|\\.)*)"/);
            englishText = englishMatch ? englishMatch[1] : '';
            response.tutorEnglish = englishText;
            console.log(`[Realtime] JSON parse failed, extracted English: "${englishText}"`);
          }

          // Send full response to client
          clientSocket.send(JSON.stringify({
            type: 'tutor_response',
            response,
          }));

          const totalTime = Date.now() - startTime;
          const streamDuration = Date.now() - streamStartTime;
          console.log(`[Realtime] Tutor: "${fullResponse.substring(0, 60)}..." | English: "${englishText.substring(0, 40)}..."`);
          console.log(`[Realtime] ⏱️ Groq streaming: ${chunkCount} chunks over ${streamDuration}ms (first chunk at ${firstChunkTime ? firstChunkTime - streamStartTime : 'N/A'}ms)`);
          console.log(`[Realtime] ⏱️ Total LLM time: ${totalTime}ms`);
        } catch (error) {
          console.error('[Realtime] Groq error:', error);
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
        // Prevent duplicate connections
        if (scribeConnecting) {
          console.log('[Realtime] Scribe connection already in progress, skipping');
          return;
        }
        scribeConnecting = true;

        // VAD silence threshold based on CEFR level:
        // - Advanced (B2/C1/C2): 0.4s - Phone call speed, holds the line for natural pauses
        // - Intermediate (B1): 0.6s - Balanced for developing fluency
        // - Beginner (A1/A2): 0.8s - Safety net, gives time to breathe and think
        const getVadSilenceThreshold = (): string => {
          switch (state.cefrLevel) {
            case 'B2':
            case 'C1':
            case 'C2':
              return '0.4';  // Advanced: fast, natural conversation flow
            case 'B1':
              return '0.6';  // Intermediate: balanced
            case 'A1':
            case 'A2':
            default:
              return '0.8';  // Beginner: more time to formulate responses
          }
        };

        const vadSilenceThreshold = getVadSilenceThreshold();
        console.log(`[Realtime] VAD silence threshold for ${state.cefrLevel}: ${vadSilenceThreshold}s`);

        const params = new URLSearchParams({
          model_id: 'scribe_v2_realtime',
          language_code: 'es',
          audio_format: 'pcm_16000',
          commit_strategy: 'vad',
          vad_silence_threshold_secs: vadSilenceThreshold,
          vad_threshold: '0.3',  // Slightly higher to avoid false triggers
          min_speech_duration_ms: '100',  // Require 100ms of speech
          min_silence_duration_ms: '150',  // Need 150ms silence to end utterance
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
          scribeConnecting = false;

          // Flush any audio that arrived while reconnecting
          if (pendingAudioChunks.length > 0) {
            console.log(`[Realtime] Flushing ${pendingAudioChunks.length} buffered audio chunks`);
            for (const chunk of pendingAudioChunks) {
              const audioBase64 = chunk.toString('base64');
              scribeSocket!.send(
                JSON.stringify({
                  message_type: 'input_audio_chunk',
                  audio_base_64: audioBase64,
                  sample_rate: 16000,
                  commit: false,
                })
              );
            }
            pendingAudioChunks = [];
          }

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
              let transcript = message.text || '';
              console.log(`[Realtime] Scribe committed: "${transcript}"`);

              // If commit is empty but we had a partial, use the partial as fallback
              if (transcript.trim().length === 0 && currentTranscript.trim().length > 0) {
                console.log(`[Realtime] Using partial as fallback: "${currentTranscript}"`);
                transcript = currentTranscript;
              }

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
                processWithLLM(transcript.trim());
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
              // Log ALL message types to debug missing partials
              console.log(`[Realtime] Scribe message: ${msgType}`, JSON.stringify(message).substring(0, 200));
            }
          } catch (e) {
            console.error('[Realtime] Error parsing Scribe message:', e);
          }
        });

        scribeSocket.on('error', (err) => {
          console.error('[Realtime] Scribe error:', err);
          scribeConnecting = false;
        });

        scribeSocket.on('close', (code, reason) => {
          console.log(`[Realtime] Scribe disconnected: ${code} ${reason}`);
          scribeSocket = null;
          scribeConnecting = false;
          // Will reconnect on-demand when audio arrives
        });
      };

      // Note: Scribe connects after 'setup' message to use correct CEFR level for VAD settings

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
              // Connect Scribe AFTER setup so we have the correct CEFR level for VAD settings
              // Close existing connection if any (in case of reconnect)
              if (scribeSocket && scribeSocket.readyState === WebSocket.OPEN) {
                scribeSocket.close();
                scribeSocket = null;
              }
              connectScribe();
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
          // Log every 100th chunk to verify audio is arriving
          if (Math.random() < 0.01) {
            console.log(`[Realtime] Audio received: ${message.length} bytes, isPaused=${state.isPaused}`);
          }

          if (!state.isPaused) {
            // Reconnect Scribe if needed (on-demand when audio arrives)
            if (!scribeSocket || scribeSocket.readyState !== WebSocket.OPEN) {
              // Buffer audio while reconnecting (limit to ~2 seconds of audio at 16kHz)
              if (pendingAudioChunks.length < 100) {
                pendingAudioChunks.push(message);
              }
              if (!scribeConnecting) {
                console.log('[Realtime] Scribe not connected, reconnecting on audio...');
                connectScribe();
              }
              return;  // Audio will flush once connected
            }

            // Convert audio to base64 and send in ElevenLabs format
            const audioBase64 = message.toString('base64');
            // Log every 50th chunk to avoid spam
            if (Math.random() < 0.02) {
              console.log(`[Realtime] Audio chunk: ${message.length} bytes`);
            }
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
