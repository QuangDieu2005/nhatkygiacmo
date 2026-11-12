import { Router } from 'express';
import { adminClient } from '../supabase.js';

const router = Router();
const fields = ['title', 'content', 'emotion', 'tags'];
function validate(body, res) {
  for (const field of ['title', 'content', 'emotion']) {
    if (typeof body[field] !== 'string' || !body[field].trim()) {
      res.status(400).json({ message: `Trường ${field} không được để trống.` });
      return false;
    }
  }
  if (body.title.length > 180 || body.content.length > 20000) {
    res.status(400).json({ message: 'Tiêu đề hoặc nội dung vượt quá giới hạn.' });
    return false;
  }
  return true;
}

router.get('/', async (req, res, next) => {
  try {
    let query = adminClient.from('dreams').select('*').eq('user_id', req.user.id);
    if (req.query.emotion) query = query.eq('emotion', String(req.query.emotion));
    if (req.query.q) {
      const q = String(req.query.q).replace(/[,%()]/g, ' ').trim();
      if (q) query = query.or(`title.ilike.%${q}%,content.ilike.%${q}%,tags.ilike.%${q}%`);
    }
    const { data, error } = await query.order('created_at', { ascending: false });
    if (error) throw error;
    res.json(data ?? []);
  } catch (error) { next(error); }
});

router.post('/', async (req, res, next) => {
  try {
    if (!validate(req.body, res)) return;
    const payload = Object.fromEntries(fields.map((key) => [key, req.body[key] ?? '']));
    payload.user_id = req.user.id;
    const { data, error } = await adminClient.from('dreams').insert(payload).select('*').single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (error) { next(error); }
});

router.patch('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isSafeInteger(id) || id <= 0) return res.status(400).json({ message: 'ID không hợp lệ.' });
    if (!validate(req.body, res)) return;
    const payload = Object.fromEntries(fields.map((key) => [key, req.body[key] ?? '']));
    const { data, error } = await adminClient.from('dreams').update(payload)
      .eq('id', id).eq('user_id', req.user.id).select('*').maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({ message: 'Không tìm thấy nhật ký.' });
    res.json(data);
  } catch (error) { next(error); }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const id = Number(req.params.id);
    if (!Number.isSafeInteger(id) || id <= 0) return res.status(400).json({ message: 'ID không hợp lệ.' });
    const { data, error } = await adminClient.from('dreams').delete()
      .eq('id', id).eq('user_id', req.user.id).select('id').maybeSingle();
    if (error) throw error;
    if (!data) return res.status(404).json({ message: 'Không tìm thấy nhật ký.' });
    res.status(204).end();
  } catch (error) { next(error); }
});
export default router;
