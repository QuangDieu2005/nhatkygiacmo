import { authClient } from './supabase.js';

export async function requireAuth(req, res, next) {
  try {
    const header = req.headers.authorization ?? '';
    const match = header.match(/^Bearer\s+(.+)$/i);
    if (!match) return res.status(401).json({ message: 'Thiếu access token. Vui lòng đăng nhập.' });
    const { data, error } = await authClient.auth.getUser(match[1]);
    if (error || !data?.user) return res.status(401).json({ message: 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn.' });
    req.user = data.user;
    next();
  } catch (error) {
    next(error);
  }
}
