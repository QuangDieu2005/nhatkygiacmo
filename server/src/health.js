export function createHealthHandler(database) {
  return async (_req, res) => {
    try {
      const { error } = await database.from('dreams_v2').select('id').limit(1);
      if (error) throw error;
      return res.json({ status: 'ok', service: 'dream-diary-api', database: 'connected' });
    } catch (_) {
      return res.status(503).json({
        status: 'degraded',
        database: 'unavailable',
        message: 'Dịch vụ cơ sở dữ liệu tạm thời không khả dụng.',
        code: 'DEPENDENCY_UNAVAILABLE',
      });
    }
  };
}
