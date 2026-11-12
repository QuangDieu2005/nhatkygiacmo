export class ApiError extends Error {
  constructor(status, code, message) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const DATE_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;
const TIMESTAMP_PATTERN = /^\d{4}-\d{2}-\d{2}T(?:[01]\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?(?:Z|[+-](?:(?:0\d|1[0-3]):[0-5]\d|14:00))$/i;

export const DREAM_EMOTIONS = new Set([
  'happy', 'peaceful', 'excited', 'sad', 'scared', 'confused', 'neutral',
]);

export function isUuid(value) {
  return typeof value === 'string' && UUID_PATTERN.test(value);
}

export function requireUuid(value, field = 'id') {
  if (!isUuid(value)) throw new ApiError(400, 'VALIDATION_ERROR', `${field} không hợp lệ.`);
  return value;
}

export function isDateOnly(value) {
  if (typeof value !== 'string') return false;
  const match = DATE_PATTERN.exec(value);
  if (!match) return false;
  const year = Number(match[1]);
  const month = Number(match[2]);
  const day = Number(match[3]);
  if (year < 1) return false;
  const date = new Date(0);
  date.setUTCHours(0, 0, 0, 0);
  date.setUTCFullYear(year, month - 1, day);
  return date.getUTCFullYear() === year &&
    date.getUTCMonth() === month - 1 &&
    date.getUTCDate() === day;
}

export function requireDateOnly(value, field) {
  if (!isDateOnly(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${field} phải theo định dạng YYYY-MM-DD.`);
  }
  return value;
}

export function parseZonedTimestamp(value, field) {
  if (typeof value !== 'string' || !TIMESTAMP_PATTERN.test(value)) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${field} phải là timestamp ISO-8601 có Z hoặc UTC offset.`);
  }
  const time = Date.parse(value);
  if (!Number.isFinite(time)) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${field} không hợp lệ.`);
  }
  const datePart = value.slice(0, 10);
  if (!isDateOnly(datePart)) {
    throw new ApiError(400, 'VALIDATION_ERROR', `${field} chứa ngày không hợp lệ.`);
  }
  return new Date(time);
}

function requireBodyObject(body) {
  if (body == null || typeof body !== 'object' || Array.isArray(body)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Request body phải là JSON object.');
  }
}

function rejectUnknownFields(body, allowed) {
  const forbidden = ['id', 'user_id', 'created_at', 'duration_minutes', 'isTracking', 'is_tracking'];
  const unknown = Object.keys(body).find((key) => forbidden.includes(key) || !allowed.includes(key));
  if (unknown) {
    throw new ApiError(400, 'VALIDATION_ERROR', `Trường ${unknown} không được phép gửi từ client.`);
  }
}

export function buildDreamPayload(body, userId) {
  requireBodyObject(body);
  const fields = ['title', 'content', 'emotion', 'tags', 'clarity_score', 'is_lucid', 'dream_date'];
  rejectUnknownFields(body, fields);

  if (typeof body.title !== 'string' || !body.title.trim() || body.title.length > 180) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Tiêu đề giấc mơ không hợp lệ.');
  }
  if (typeof body.content !== 'string' || !body.content.trim() || body.content.length > 20000) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Nội dung giấc mơ không hợp lệ.');
  }
  if (typeof body.emotion !== 'string' || !DREAM_EMOTIONS.has(body.emotion)) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Cảm xúc giấc mơ không hợp lệ.');
  }
  const tags = body.tags ?? [];
  if (!Array.isArray(tags) || tags.some((tag) => typeof tag !== 'string')) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'tags phải là mảng chuỗi.');
  }
  const clarityScore = body.clarity_score ?? 3;
  if (!Number.isInteger(clarityScore) || clarityScore < 1 || clarityScore > 5) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'clarity_score phải từ 1 đến 5.');
  }
  const isLucid = body.is_lucid ?? false;
  if (typeof isLucid !== 'boolean') {
    throw new ApiError(400, 'VALIDATION_ERROR', 'is_lucid phải là boolean.');
  }

  return {
    title: body.title.trim(),
    content: body.content.trim(),
    emotion: body.emotion,
    tags: [...tags],
    clarity_score: clarityScore,
    is_lucid: isLucid,
    dream_date: requireDateOnly(body.dream_date, 'dream_date'),
    user_id: requireUuid(userId, 'user_id'),
  };
}

export function buildSleepPayload(body, userId) {
  requireBodyObject(body);
  const fields = [
    'start_time', 'end_time', 'quality_score', 'deep_sleep_minutes',
    'light_sleep_minutes', 'rem_sleep_minutes', 'notes',
  ];
  rejectUnknownFields(body, fields);

  const startTime = parseZonedTimestamp(body.start_time, 'start_time');
  const endTime = parseZonedTimestamp(body.end_time, 'end_time');
  const elapsedMilliseconds = endTime.getTime() - startTime.getTime();
  if (elapsedMilliseconds <= 0 || elapsedMilliseconds > 24 * 60 * 60 * 1000) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'Khoảng thời gian ngủ phải lớn hơn 0 và không quá 24 giờ.');
  }

  const qualityScore = body.quality_score;
  if (!Number.isInteger(qualityScore) || qualityScore < 0 || qualityScore > 100) {
    throw new ApiError(400, 'VALIDATION_ERROR', 'quality_score phải là số nguyên từ 0 đến 100.');
  }
  const stages = {};
  for (const field of ['deep_sleep_minutes', 'light_sleep_minutes', 'rem_sleep_minutes']) {
    const value = body[field] ?? 0;
    if (!Number.isInteger(value) || value < 0) {
      throw new ApiError(400, 'VALIDATION_ERROR', `${field} phải là số nguyên không âm.`);
    }
    stages[field] = value;
  }
  const notes = body.notes ?? '';
  if (typeof notes !== 'string') {
    throw new ApiError(400, 'VALIDATION_ERROR', 'notes phải là chuỗi hoặc null.');
  }

  return {
    user_id: requireUuid(userId, 'user_id'),
    start_time: startTime.toISOString(),
    end_time: endTime.toISOString(),
    duration_minutes: Math.floor(elapsedMilliseconds / 60000),
    quality_score: qualityScore,
    ...stages,
    notes,
  };
}
