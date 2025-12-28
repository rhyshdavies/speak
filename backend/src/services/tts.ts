import { ElevenLabsClient } from '@elevenlabs/elevenlabs-js';

// ElevenLabs client singleton
let elevenLabsClient: ElevenLabsClient | null = null;

function getElevenLabsClient(): ElevenLabsClient {
  if (!elevenLabsClient) {
    const apiKey = process.env.ELEVEN_LABS_API_KEY;
    if (!apiKey) {
      throw new Error('ELEVEN_LABS_API_KEY environment variable is not set');
    }
    elevenLabsClient = new ElevenLabsClient({ apiKey });
  }
  return elevenLabsClient;
}

/**
 * Synthesize Spanish text to audio using ElevenLabs Flash v2.5
 * @param text - Spanish text to synthesize
 * @returns MP3 audio buffer
 */
export async function synthesizeSpeech(text: string): Promise<Buffer> {
  const client = getElevenLabsClient();

  // Charlotte voice - clear, natural multilingual
  const voiceId = 'XB0fDUnXU5powFXDhCwa';

  const audioStream = await client.textToSpeech.convert(voiceId, {
    text,
    model_id: 'eleven_flash_v2_5',
    output_format: 'mp3_22050_32',
  });

  // Convert stream to buffer
  const chunks: Buffer[] = [];
  for await (const chunk of audioStream) {
    chunks.push(Buffer.from(chunk));
  }

  return Buffer.concat(chunks);
}
