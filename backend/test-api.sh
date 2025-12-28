#!/bin/bash
# Test the conversation API endpoint

AUDIO_FILE="/tmp/test_spanish.wav"
DATA='{"messages":[],"scenario":{"type":"restaurant","title":"Restaurant Order","description":"Order food","setting":"Spanish restaurant","userRole":"Customer","tutorRole":"Waiter","objectives":["Order food"]},"cefrLevel":"A1"}'

echo "Testing conversation API..."
echo "Audio file: $AUDIO_FILE"
echo ""

RESPONSE=$(curl -s -X POST http://localhost:3000/api/conversation/turn \
  -F "audio=@${AUDIO_FILE}" \
  -F "data=${DATA}")

echo "Response:"
echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
