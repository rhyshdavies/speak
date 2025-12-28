import fs from 'fs';

/**
 * Transcribe audio file to Spanish text using ElevenLabs Scribe v1
 * Fast transcription for file-based audio
 * @param audioFilePath - Path to the audio file (m4a, wav, mp3, etc.)
 * @param originalFilename - Original filename with extension (e.g., "recording.m4a")
 * @returns Transcribed text in Spanish
 */
export async function transcribeAudio(
  audioFilePath: string,
  originalFilename: string = 'recording.m4a'
): Promise<string> {
  const apiKey = process.env.ELEVEN_LABS_API_KEY;
  if (!apiKey) {
    throw new Error('ELEVEN_LABS_API_KEY environment variable is not set');
  }

  // Read the audio file
  const audioBuffer = fs.readFileSync(audioFilePath);
  const audioBlob = new Blob([audioBuffer], { type: 'audio/m4a' });

  // Create FormData with the correct field names
  const formData = new FormData();
  formData.append('file', audioBlob, originalFilename);
  formData.append('model_id', 'scribe_v1');
  formData.append('language_code', 'es');

  const response = await fetch('https://api.elevenlabs.io/v1/speech-to-text', {
    method: 'POST',
    headers: {
      'xi-api-key': apiKey,
    },
    body: formData,
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`ElevenLabs STT error ${response.status}: ${errorBody}`);
  }

  const result = await response.json() as { text?: string };
  return result.text || '';
}
