import { Router } from 'express';
import {
  ApiError,
  DREAM_EMOTIONS,
  buildDreamPayload,
  requireDateOnly,
  requireUuid,
} from '../validation.js';

function requireQueryString(value, field) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new ApiError(400, 'VALIDATION_ERROR', `Tham số ${field} không hợp lệ.`);
  }
  return value.trim();
}

export function createDreamsRouter(database) {
  const router = Router();

  router.get('/', async (req, res, next) => {
    try {
      let query = database.from('dreams').select('*').eq('user_id', req.user.id);

      if (req.query.emotion !== undefined) {
        const emotion = requireQueryString(req.query.emotion, 'emotion');
        if (!DREAM_EMOTIONS.has(emotion)) {
          throw new ApiError(400, 'VALIDATION_ERROR', 'Cảm xúc giấc mơ không hợp lệ.');
        }
        query = query.eq('emotion', emotion);
      }
      if (req.query.q !== undefined) {
        const q = requireQueryString(req.query.q, 'q').replace(/[,.%*()\\]/g, ' ').trim();
        if (q) query = query.or(`title.ilike.%${q}%,content.ilike.%${q}%`);
      }
      if (req.query.tag !== undefined) {
        const tag = requireQueryString(req.query.tag, 'tag');
        query = query.contains('tags', [tag]);
      }

      const from = req.query.from === undefined
        ? null
        : requireDateOnly(requireQueryString(req.query.from, 'from'), 'from');
      const to = req.query.to === undefined
        ? null
        : requireDateOnly(requireQueryString(req.query.to, 'to'), 'to');
      if (from && to && from > to) {
        throw new ApiError(400, 'VALIDATION_ERROR', 'Khoảng ngày lọc không hợp lệ.');
      }
      if (from) query = query.gte('dream_date', from);
      if (to) query = query.lte('dream_date', to);

      const { data, error } = await query.order('created_at', { ascending: false });
      if (error) throw error;
      return res.json(data ?? []);
    } catch (error) {
      return next(error);
    }
  });

  router.post('/', async (req, res, next) => {
    try {
      const payload = buildDreamPayload(req.body, req.user.id);
      const { data, error } = await database
        .from('dreams')
        .insert(payload)
        .select('*')
        .single();
      if (error) throw error;
      return res.status(201).json(data);
    } catch (error) {
      return next(error);
    }
  });

  router.patch('/:id', async (req, res, next) => {
    try {
      const id = requireUuid(req.params.id);
      const payload = buildDreamPayload(req.body, req.user.id);
      const { data, error } = await database
        .from('dreams')
        .update(payload)
        .eq('id', id)
        .eq('user_id', req.user.id)
        .select('*')
        .maybeSingle();
      if (error) throw error;
      if (!data) {
        throw new ApiError(404, 'NOT_FOUND', 'Không tìm thấy nhật ký.');
      }
      return res.json(data);
    } catch (error) {
      return next(error);
    }
  });

  router.delete('/:id', async (req, res, next) => {
    try {
      const id = requireUuid(req.params.id);
      const { data, error } = await database
        .from('dreams')
        .delete()
        .eq('id', id)
        .eq('user_id', req.user.id)
        .select('id')
        .maybeSingle();
      if (error) throw error;
      if (!data) {
        throw new ApiError(404, 'NOT_FOUND', 'Không tìm thấy nhật ký.');
      }
      return res.status(204).end();
    } catch (error) {
      return next(error);
    }
  });

  return router;
}
