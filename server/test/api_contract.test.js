import assert from 'node:assert/strict';
import test from 'node:test';
import { createDreamsRouter } from '../src/routes/dreams.js';
import { createSleepRecordsRouter } from '../src/routes/sleepRecords.js';
import { apiErrorHandler } from '../src/errorHandler.js';
import {
  buildDreamPayload,
  buildSleepPayload,
  isDateOnly,
  isUuid,
} from '../src/validation.js';

const USER_ID = '123e4567-e89b-42d3-a456-426614174000';
const DREAM_ID = '550e8400-e29b-41d4-a716-446655440000';
const CREATED_AT = '2025-03-10T08:00:00.000Z';

test('validates UUID path identifiers and date-only values', () => {
  assert.equal(isUuid(DREAM_ID), true);
  assert.equal(isUuid('17'), false);
  assert.equal(isDateOnly('2025-02-28'), true);
  assert.equal(isDateOnly('2025-02-30'), false);
  assert.equal(isDateOnly('2025-02-28T00:00:00Z'), false);
});

test('dream payload validates tags and only takes owner from verified request user', () => {
  const payload = buildDreamPayload(dreamBody(), USER_ID);
  assert.deepEqual(payload.tags, ['moon', 'night']);
  assert.equal(payload.user_id, USER_ID);
  assert.equal(Object.hasOwn(payload, 'id'), false);
  assert.equal(Object.hasOwn(payload, 'created_at'), false);

  assert.throws(
    () => buildDreamPayload({...dreamBody(), tags: 'moon,night'}, USER_ID),
    /tags phải là mảng chuỗi/,
  );
  assert.throws(
    () => buildDreamPayload({...dreamBody(), user_id: 'attacker'}, USER_ID),
    /không được phép gửi từ client/,
  );
});

test('dream list uses array containment, searches only text fields, and scopes owner', async () => {
  const database = new FakeDatabase();
  const router = createDreamsRouter(database);
  const response = await invoke(router, 'get', '/', {
    query: {q: 'moon', tag: 'night', emotion: 'peaceful', from: '2025-03-01', to: '2025-03-31'},
  });
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.body, []);

  const call = database.calls.at(-1);
  assert.ok(call.filters.some(([field, value]) => field === 'user_id' && value === USER_ID));
  assert.deepEqual(call.contains, [['tags', ['night']]]);
  assert.match(call.or, /title\.ilike/);
  assert.match(call.or, /content\.ilike/);
  assert.doesNotMatch(call.or, /tags/);
  assert.deepEqual(call.filters.filter(([field]) => field === 'dream_date'), [
    ['dream_date', 'gte', '2025-03-01'],
    ['dream_date', 'lte', '2025-03-31'],
  ]);
});

test('Dream create rejects client metadata and returns a full object with JWT owner', async () => {
  const database = new FakeDatabase();
  const router = createDreamsRouter(database);
  const invalid = await invoke(router, 'post', '/', {
    body: {...dreamBody(), id: DREAM_ID},
  });
  assert.equal(invalid.statusCode, 400);
  assert.equal(invalid.body.code, 'VALIDATION_ERROR');

  const response = await invoke(router, 'post', '/', {body: dreamBody()});
  assert.equal(response.statusCode, 201);
  assert.equal(response.body.user_id, USER_ID);
  const saved = database.calls.at(-1).payload;
  assert.deepEqual(saved.tags, ['moon', 'night']);
  assert.equal(saved.dream_date, '2025-03-10');
  assert.equal(Object.hasOwn(saved, 'id'), false);
  assert.equal(Object.hasOwn(saved, 'created_at'), false);
});

test('Dream mutations validate UUID and filter writes by JWT owner', async () => {
  const database = new FakeDatabase();
  const router = createDreamsRouter(database);
  const invalid = await invoke(router, 'delete', '/:id', {params: {id: 'not-a-uuid'}});
  assert.equal(invalid.statusCode, 400);

  const updated = await invoke(router, 'patch', '/:id', {
    params: {id: DREAM_ID}, body: dreamBody(),
  });
  assert.equal(updated.statusCode, 200);
  assert.ok(database.calls.at(-1).filters.some(([key, value]) => key === 'id' && value === DREAM_ID));
  assert.ok(database.calls.at(-1).filters.some(([key, value]) => key === 'user_id' && value === USER_ID));

  const removed = await invoke(router, 'delete', '/:id', {params: {id: DREAM_ID}});
  assert.equal(removed.statusCode, 204);
  assert.ok(database.calls.at(-1).filters.some(([key, value]) => key === 'user_id' && value === USER_ID));
});

test('sleep payload validates zoned timestamps and computes duration server-side', () => {
  const payload = buildSleepPayload({
    start_time: '2025-03-10T22:00:00+07:00',
    end_time: '2025-03-11T06:00:00+07:00',
    quality_score: 88,
    deep_sleep_minutes: 120,
    light_sleep_minutes: 260,
    rem_sleep_minutes: 100,
    notes: 'Rested',
  }, USER_ID);
  assert.equal(payload.start_time, '2025-03-10T15:00:00.000Z');
  assert.equal(payload.end_time, '2025-03-10T23:00:00.000Z');
  assert.equal(payload.duration_minutes, 480);
  assert.equal(payload.user_id, USER_ID);
  assert.equal(Object.hasOwn(payload, 'isTracking'), false);

  assert.throws(() => buildSleepPayload({
    ...sleepBody(), start_time: '2025-03-10T22:00:00',
  }, USER_ID), /phải là timestamp ISO-8601/);
  assert.throws(() => buildSleepPayload({
    ...sleepBody(), duration_minutes: 480,
  }, USER_ID), /không được phép gửi từ client/);
  assert.throws(() => buildSleepPayload({
    ...sleepBody(), isTracking: true,
  }, USER_ID), /không được phép gửi từ client/);
});

test('Sleep create normalizes timestamps, calculates duration, and scopes owner', async () => {
  const database = new FakeDatabase();
  const router = createSleepRecordsRouter(database);
  const response = await invoke(router, 'post', '/', {
    body: {
      ...sleepBody(),
      start_time: '2025-03-10T22:00:00+07:00',
      end_time: '2025-03-11T06:00:00+07:00',
    },
  });
  assert.equal(response.statusCode, 201);
  const saved = database.calls.at(-1).payload;
  assert.equal(saved.duration_minutes, 480);
  assert.equal(saved.start_time, '2025-03-10T15:00:00.000Z');
  assert.equal(saved.user_id, USER_ID);
  for (const field of ['id', 'created_at', 'isTracking', 'is_tracking']) {
    assert.equal(Object.hasOwn(saved, field), false);
  }
});

test('Sleep routes validate UUIDs and owner-scope update/delete', async () => {
  const database = new FakeDatabase();
  const router = createSleepRecordsRouter(database);
  const invalid = await invoke(router, 'delete', '/:id', {params: {id: '42'}});
  assert.equal(invalid.statusCode, 400);

  const updated = await invoke(router, 'patch', '/:id', {
    params: {id: DREAM_ID}, body: sleepBody(),
  });
  assert.equal(updated.statusCode, 200);
  assert.ok(database.calls.at(-1).filters.some(([field, value]) => field === 'user_id' && value === USER_ID));

  const removed = await invoke(router, 'delete', '/:id', {params: {id: DREAM_ID}});
  assert.equal(removed.statusCode, 204);
  assert.ok(database.calls.at(-1).filters.some(([field, value]) => field === 'user_id' && value === USER_ID));
});

test('sleep GET returns a direct array with a JWT owner filter', async () => {
  const database = new FakeDatabase();
  const router = createSleepRecordsRouter(database);
  const response = await invoke(router, 'get', '/', {query: {days: '7'}});
  assert.equal(response.statusCode, 200);
  assert.deepEqual(response.body, []);
  assert.ok(database.calls.at(-1).filters.some(([field, value]) => field === 'user_id' && value === USER_ID));
});

test('unexpected database errors are returned as a generic error DTO', () => {
  const response = fakeResponse();
  apiErrorHandler(new Error('private database detail'), {}, response, () => {});
  assert.equal(response.statusCode, 500);
  assert.equal(response.body.code, 'INTERNAL_ERROR');
  assert.doesNotMatch(response.body.message, /private database detail/);
});

async function invoke(router, method, path, overrides = {}) {
  const layer = router.stack.find((entry) =>
    entry.route?.path === path && entry.route.methods[method]);
  assert.ok(layer, `Missing ${method.toUpperCase()} ${path} route`);
  const handler = layer.route.stack[0].handle;
  const response = fakeResponse();
  const request = {
    user: {id: USER_ID},
    params: {},
    query: {},
    body: {},
    ...overrides,
  };
  await handler(request, response, (error) => {
    apiErrorHandler(error, request, response, () => {});
  });
  return response;
}

function fakeResponse() {
  return {
    statusCode: 200,
    body: undefined,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = body; return this; },
    end() { return this; },
  };
}

function dreamBody() {
  return {
    title: 'Quiet night',
    content: 'Walking under the moon.',
    emotion: 'peaceful',
    tags: ['moon', 'night'],
    clarity_score: 4,
    is_lucid: false,
    dream_date: '2025-03-10',
  };
}

function sleepBody() {
  return {
    start_time: '2025-03-10T15:00:00Z',
    end_time: '2025-03-10T23:00:00Z',
    quality_score: 88,
    deep_sleep_minutes: 120,
    light_sleep_minutes: 260,
    rem_sleep_minutes: 100,
    notes: 'Rested',
  };
}

class FakeDatabase {
  calls = [];

  from(table) {
    const call = {table, filters: [], contains: [], payload: null, operation: 'select', or: null};
    this.calls.push(call);
    return new FakeQuery(call);
  }
}

class FakeQuery {
  constructor(call) { this.call = call; }
  select() { return this; }
  eq(field, value) { this.call.filters.push([field, value]); return this; }
  gte(field, value) { this.call.filters.push([field, 'gte', value]); return this; }
  lte(field, value) { this.call.filters.push([field, 'lte', value]); return this; }
  contains(field, value) { this.call.contains.push([field, value]); return this; }
  or(value) { this.call.or = value; return this; }
  order() { return this; }
  insert(payload) { this.call.operation = 'insert'; this.call.payload = payload; return this; }
  update(payload) { this.call.operation = 'update'; this.call.payload = payload; return this; }
  delete() { this.call.operation = 'delete'; return this; }
  async single() { return {data: this.row(), error: null}; }
  async maybeSingle() {
    return {data: this.call.operation === 'delete' ? {id: DREAM_ID} : this.row(), error: null};
  }
  then(resolve, reject) { return Promise.resolve({data: [], error: null}).then(resolve, reject); }
  row() { return {...this.call.payload, id: DREAM_ID, created_at: CREATED_AT}; }
}
