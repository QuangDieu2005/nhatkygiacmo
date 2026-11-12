import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { apiErrorHandler } from './errorHandler.js';
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

app.get('/api/health', async (_req, res) => {
  const { error } = await adminClient.from('dreams').select('id').limit(1);
  if (error) return res.status(503).json({
    status: 'degraded',
    database: 'unavailable',
    message: 'Dịch vụ cơ sở dữ liệu tạm thời không khả dụng.',
    code: 'DEPENDENCY_UNAVAILABLE',
  });
  res.json({ status: 'ok', service: 'dream-diary-api', database: 'connected' });
});

app.use('/api/auth', authRouter);
app.use('/api/dreams', requireAuth, createDreamsRouter(adminClient));
app.use('/api/sleep-records', requireAuth, createSleepRecordsRouter(adminClient));
app.delete('/api/account/data', requireAuth, async (req, res, next) => {
  try {
    const userId = req.user.id;
    const dreams = await adminClient.from('dreams').delete().eq('user_id', userId);
    if (dreams.error) throw dreams.error;
    const sleeps = await adminClient.from('sleep_records').delete().eq('user_id', userId);
    if (sleeps.error) throw sleeps.error;
    res.json({ success: true, message: 'Đã xóa dữ liệu nhật ký và giấc ngủ của tài khoản.' });
  } catch (error) { next(error); }
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
