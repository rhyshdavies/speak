// Load environment variables FIRST before any other imports
import 'dotenv/config';

import express from 'express';
import { createServer } from 'http';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import conversationRouter from './routes/conversation.js';
import { RealtimeServer } from './services/realtime/RealtimeServer.js';

const app = express();
const server = createServer(app);
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());

// CORS configuration - allow iOS app
app.use(
  cors({
    origin: '*', // Allow all origins (iOS app)
    methods: ['POST', 'GET', 'OPTIONS'],
  })
);

// Body parser for JSON
app.use(express.json({ limit: '10mb' }));

// Rate limiting: 15 requests per minute per IP
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 15, // 15 requests per minute
  message: { error: 'Too many requests, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});
app.use('/api/', limiter);

// Routes
app.use('/api/conversation', conversationRouter);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    name: 'Speak API',
    version: '1.0.0',
    modes: {
      beginner: 'REST API - Turn-based conversation (~2.6s latency)',
      advanced: 'WebSocket - Real-time streaming (sub-500ms latency)',
    },
    endpoints: {
      health: 'GET /health',
      conversationTurn: 'POST /api/conversation/turn (Beginner Mode)',
      realtimeWebSocket: 'ws://<host>:<port> (Advanced Mode - same port as REST)',
    },
  });
});

// Global error handler
app.use(
  (
    err: Error,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    console.error('Unhandled error:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
);

// Start WebSocket server (Advanced Mode) - attach to HTTP server if ElevenLabs key is set
if (process.env.ELEVEN_LABS_API_KEY) {
  try {
    new RealtimeServer(server);
    console.log(`⚡ Advanced Mode (WebSocket): Enabled on same port`);
  } catch (error) {
    console.log(`⚠️  Advanced Mode disabled (WebSocket server failed to start)`);
  }
} else {
  console.log(`⚠️  Advanced Mode disabled (ELEVEN_LABS_API_KEY not set)`);
}

// Start HTTP server (serves both REST and WebSocket on same port)
server.listen(PORT, '0.0.0.0', () => {
  console.log(`\n📱 Speak Backend Started on port ${PORT}`);
  console.log(`════════════════════════════════════════`);
  console.log(`🐢 Beginner Mode (REST): http://localhost:${PORT}`);
  console.log(`⚡ Advanced Mode (WebSocket): ws://localhost:${PORT}`);
  console.log(`════════════════════════════════════════\n`);
});

export default app;
