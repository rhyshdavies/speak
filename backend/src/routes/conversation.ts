import { Router, Request, Response } from 'express';
import multer from 'multer';
import fs from 'fs/promises';
import os from 'os';
import path from 'path';
import { transcribeAudio } from '../services/whisper.js';
import { generateTutorResponse } from '../services/chat.js';
import { synthesizeSpeech } from '../services/tts.js';
import type {
  ConversationTurnRequest,
  TurnResponse,
  APIError,
} from '../types/index.js';

const router = Router();

// Configure multer for file uploads
const upload = multer({
  dest: os.tmpdir(),
  limits: {
    fileSize: 10 * 1024 * 1024, // 10MB max
  },
});

/**
 * POST /api/conversation/turn
 * Process a single conversation turn:
 * 1. Transcribe user audio with Whisper
 * 2. Generate tutor response with GPT-4o-mini
 * 3. Synthesize response audio with TTS-1
 */
router.post(
  '/turn',
  upload.single('audio'),
  async (req: Request, res: Response): Promise<void> => {
    const tempFilePath = req.file?.path;

    try {
      // Validate audio file
      if (!req.file) {
        const error: APIError = { error: 'No audio file provided' };
        res.status(400).json(error);
        return;
      }

      // Parse request data
      const dataField = req.body.data;
      if (!dataField) {
        const error: APIError = { error: 'No request data provided' };
        res.status(400).json(error);
        return;
      }

      let requestData: ConversationTurnRequest;
      try {
        requestData = JSON.parse(dataField);
      } catch {
        const error: APIError = { error: 'Invalid JSON in data field' };
        res.status(400).json(error);
        return;
      }

      const { messages, scenario, cefrLevel } = requestData;

      // Validate required fields
      if (!scenario || !cefrLevel) {
        const error: APIError = {
          error: 'Missing required fields: scenario and cefrLevel',
        };
        res.status(400).json(error);
        return;
      }

      const totalStart = Date.now();
      console.log(
        `[Turn] Processing: scenario=${scenario.type}, level=${cefrLevel}`
      );

      // Step 1: Transcribe audio with ElevenLabs Scribe
      console.log('[Turn] Step 1: Transcribing audio...');
      const sttStart = Date.now();
      const originalFilename = req.file.originalname || 'recording.m4a';
      const userTranscript = await transcribeAudio(tempFilePath!, originalFilename);
      const sttTime = Date.now() - sttStart;
      console.log(`[Turn] Transcript: "${userTranscript}" (${sttTime}ms)`);

      // Step 2: Generate tutor response with GPT-5-mini
      console.log('[Turn] Step 2: Generating tutor response...');
      const chatStart = Date.now();
      const tutorResponse = await generateTutorResponse(
        messages || [],
        scenario,
        cefrLevel,
        userTranscript
      );
      const chatTime = Date.now() - chatStart;
      console.log(`[Turn] Tutor: "${tutorResponse.tutorSpanish}" (${chatTime}ms)`);

      // Step 3: Synthesize speech with ElevenLabs Flash
      console.log('[Turn] Step 3: Synthesizing speech...');
      const ttsStart = Date.now();
      const audioBuffer = await synthesizeSpeech(tutorResponse.tutorSpanish);
      const ttsTime = Date.now() - ttsStart;
      const audioBase64 = audioBuffer.toString('base64');
      console.log(`[Turn] Audio size: ${audioBuffer.length} bytes (${ttsTime}ms)`);

      // Build response
      const response: TurnResponse = {
        userTranscript,
        tutorResponse,
        audioBase64,
        audioMimeType: 'audio/mpeg',
      };

      const totalTime = Date.now() - totalStart;
      console.log(`[Turn] Complete - STT: ${sttTime}ms | Chat: ${chatTime}ms | TTS: ${ttsTime}ms | Total: ${totalTime}ms`);
      res.json(response);
    } catch (error) {
      console.error('[Turn] Error:', error);

      const apiError: APIError = {
        error: 'Failed to process conversation turn',
        details: error instanceof Error ? error.message : 'Unknown error',
      };
      res.status(500).json(apiError);
    } finally {
      // Clean up temp file
      if (tempFilePath) {
        await fs.unlink(tempFilePath).catch(() => {
          // Ignore cleanup errors
        });
      }
    }
  }
);

export default router;
