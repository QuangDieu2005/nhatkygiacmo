import { Router } from 'express';
import {
  ApiError,
  buildSleepPayload,
  isDateOnly,
  requireUuid,
} from '../validation.js';

function dateQuery(value, field) {
  if (typeof value !== 'string' || !isDateOnly(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${field} phải theo định dạng YYYY-MM-DD.`);
  }
  return value;
}

export function createSleepRecordsRouter(database) {
  const router = Router();

  router.get('/', async (req, res, next) => {
    try {
      const from = req.query.from === undefined ? null : dateQuery(req.query.from, 'from');
      const to = req.query.to === undefined ? null : dateQuery(req.query.to, 'to');
      if (from && to && from > to) {
        throw new ApiError(400, 'VALIDATION_ERROR', 'Khoảng ngày lọc không hợp lệ.');
      }

      let query = database.from('sleep_records_v2').select('*').eq('user_id', req.user.id);
      if (from || to) {
        if (from) query = query.gte('start_time', `${from}T00:00:00.000Z`);
        if (to) query = query.lte('start_time', `${to}T23:59:59.999Z`);
      } else {
        const daysValue = req.query.days === undefined ? 90 : Number(req.query.days);
        if (!Number.isInteger(daysValue) || daysValue < 1 || daysValue > 3650) {
          throw new ApiError(400, 'VALIDATION_ERROR', 'days phải là số nguyên từ 1 đến 3650.');
        }
        const since = new Date(Date.now() - daysValue * 86400000).toISOString();
        query = query.gte('created_at', since);
      }

      const { data, error } = await query.order('created_at', { ascending: false });
      if (error) throw error;
      return res.json(data ?? []);
    } catch (error) {
      return next(error);
    }
  });

  router.post('/', async (req, res, next) => {
    try {
      const payload = buildSleepPayload(req.body, req.user.id);
      const { data, error } = await database
        .from('sleep_records_v2')
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
      const payload = buildSleepPayload(req.body, req.user.id);
      const { data, error } = await database
        .from('sleep_records_v2')
        .update(payload)
        .eq('id', id)
        .eq('user_id', req.user.id)
        .select('*')
        .maybeSingle();
      if (error) throw error;
      if (!data) {
        throw new ApiError(404, 'NOT_FOUND', 'Không tìm thấy bản ghi giấc ngủ.');
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
        .from('sleep_records_v2')
        .delete()
        .eq('id', id)
        .eq('user_id', req.user.id)
        .select('id')
        .maybeSingle();
      if (error) throw error;
      if (!data) {
        throw new ApiError(404, 'NOT_FOUND', 'Không tìm thấy bản ghi giấc ngủ.');
      }
      return res.status(204).end();
    } catch (error) {
      return next(error);
    }
  });

  return router;
}
