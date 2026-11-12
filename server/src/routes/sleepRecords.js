import { Router } from 'express';
import { adminClient } from '../supabase.js';

const router = Router();
const fields = ['sleep_time', 'wake_time', 'duration_minutes', 'quality', 'note'];
function validate(body, res) {
  if (typeof body.sleep_time !== 'string' || !body.sleep_time.trim() ||
      typeof body.wake_time !== 'string' || !body.wake_time.trim()) {
    res.status(400).json({ message: 'Vui lòng nhập giờ ngủ và giờ thức dậy.' }); return false;
  }
  const duration = Number(body.duration_minutes);
  const quality = Number(body.quality);
  if (!Number.isInteger(duration) || duration < 0 || duration > 1440) {
    res.status(400).json({ message: 'Thời lượng ngủ không hợp lệ.' }); return false;
  }
  if (!Number.isInteger(quality) || quality < 1 || quality > 10) {
    res.status(400).json({ message: 'Chất lượng ngủ phải từ 1 đến 10.' }); return false;
  }
  return true;
}
function payloadFrom(body, userId) {
  return {
    sleep_time: body.sleep_time,
    wake_time: body.wake_time,
    duration_minutes: Number(body.duration_minutes),
    quality: Number(body.quality),
    note: body.note ?? '',
    ...(userId ? { user_id: userId } : {}),
  };
}

router.get('/', async (req, res, next) => {
  try {
    const days = Math.min(Math.max(Number(req.query.days) || 90, 1), 3650);
    const since = new Date(Date.now() - days * 86400000).toISOString();
    const { data, error } = await adminClient.from('sleep_records').select('*')
      .eq('user_id', req.user.id).gte('created_at', since)
      .order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data ?? []);
  } catch (error) { next(error); }
});

router.post('/', async (req, res, next) => {
  try {
    if (!validate(req.body, res)) return;
    const { data, error } = await adminClient.from('sleep_records')
      .insert(payloadFrom(req.body, req.user.id)).select('*').single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (error) { next(error); }
});

router.patch('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isSafeInteger(id) || id <= 0) return res.status(400).json({ message: 'ID không hợp lệ.' });
    if (!validate(req.body, res)) return;
    const { data, error } = await adminClient.from('sleep_records').update(payloadFrom(req.body))
      .eq('id', id).eq('user_id', req.user.id).select('*').maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({ message: 'Không tìm thấy bản ghi giấc ngủ.' });
    res.json(data);
  } catch (error) { next(error); }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isSafeInteger(id) || id <= 0) return res.status(400).json({ message: 'ID không hợp lệ.' });
    const { data, error } = await adminClient.from('sleep_records').delete()
      .eq('id', id).eq('user_id', req.user.id).select('id').maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({ message: 'Không tìm thấy bản ghi giấc ngủ.' });
    res.status(204).end();
  } catch (error) { next(error); }
});
export default router;
