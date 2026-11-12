import { ApiError } from './validation.js';

export function apiErrorHandler(error, _req, res, _next) {
  if (error instanceof ApiError) {
    return res.status(error.status).json({ message: error.message, code: error.code });
  }
  console.error('[API error]', error?.name ?? 'UnknownError');
  return res.status(500).json({
    message: 'Máy chủ gặp lỗi khi xử lý yêu cầu.',
    code: 'INTERNAL_ERROR',
  });
}
