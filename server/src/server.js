import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { apiErrorHandler } from './errorHandler.js';
import { createHealthHandler } from './health.js';
import { adminClient } from './supabase.js';
import { requireAuth } from './middleware.js';
import authRouter from './routes/auth.js';
import { createDreamsRouter } from './routes/dreams.js';
import { createSleepRecordsRouter } from './routes/sleepRecords.js';

const app = express();
const port = Number(process.env.PORT) || 3000;
app.disable('x-powered-by');
app.use(helmet());
const origins = (process.env.CORS_ORIGIN || '*').split(',').map((v) => v.trim());
app.use(cors({ origin: origins.includes('*') ? '*' : origins }));
app.use(express.json({ limit: '1mb' }));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 300, standardHeaders: 'draft-8', legacyHeaders: false }));

app.get('/api/health', createHealthHandler(adminClient));

app.use('/api/auth', authRouter);
app.use('/api/dreams', requireAuth, createDreamsRouter(adminClient));
app.use('/api/sleep-records', requireAuth, createSleepRecordsRouter(adminClient));
app.delete('/api/account/data', requireAuth, async (_req, res) => {
  // Disabled until an atomic, reviewed operation covers both legacy and v2 tables.
  res.status(501).json({
    message: 'Chức năng xóa dữ liệu tài khoản tạm thời chưa khả dụng.',
    code: 'NOT_SUPPORTED',
  });
});

app.use((_req, res) => res.status(404).json({
  message: 'Không tìm thấy API endpoint.',
  code: 'NOT_FOUND',
}));
app.use(apiErrorHandler);

app.listen(port, '0.0.0.0', () => {
  console.log(`Dream Diary API is running at http://localhost:${port}`);
  console.log(`Health check: http://localhost:${port}/api/health`);
});
