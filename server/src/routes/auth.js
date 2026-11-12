import { Router } from 'express';

const router = Router();
const supabaseUrl = process.env.SUPABASE_URL?.replace(/\/+$/, '');
const anonKey = process.env.SUPABASE_ANON_KEY;

async function supabaseAuth(path, { body, accessToken } = {}) {
  const response = await fetch(`${supabaseUrl}/auth/v1/${path}`, {
    method: 'POST',
    headers: {
      apikey: anonKey,
      'Content-Type': 'application/json',
      ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
    },
    ...(body === undefined ? {} : { body: JSON.stringify(body) }),
  });
  const data = response.status === 204 ? null : await response.json();
  if (!response.ok) {
    const error = new Error(
      data?.msg ?? data?.message ?? data?.error_description ?? 'Xác thực thất bại.',
    );
    error.status = response.status;
    throw error;
  }
  return data;
}

router.post('/register', async (req, res, next) => {
  try {
    const name = typeof req.body.name === 'string' ? req.body.name.trim() : '';
    const email = typeof req.body.email === 'string' ? req.body.email.trim().toLowerCase() : '';
    const password = typeof req.body.password === 'string' ? req.body.password : '';
    if (!name || !email || password.length < 8) {
      return res.status(400).json({ message: 'Vui lòng nhập tên, email hợp lệ và mật khẩu từ 8 ký tự.' });
    }
    const data = await supabaseAuth('signup', {
      body: { email, password, data: { name } },
    });
    return res.status(data?.session ? 201 : 202).json({
      user: data?.user ?? null,
      session: data?.session ?? null,
      confirmation_required: !data?.session,
    });
  } catch (error) {
    return res.status(error.status ?? 500).json({ message: error.message });
  }
});

router.post('/login', async (req, res, next) => {
  try {
    const email = typeof req.body.email === 'string' ? req.body.email.trim().toLowerCase() : '';
    const password = typeof req.body.password === 'string' ? req.body.password : '';
    if (!email || !password) {
      return res.status(400).json({ message: 'Vui lòng nhập email và mật khẩu.' });
    }
    const data = await supabaseAuth('token?grant_type=password', {
      body: { email, password },
    });
    return res.json({ user: data.user, session: data });
  } catch (error) {
    return res.status(error.status ?? 500).json({ message: error.message });
  }
});

router.post('/refresh', async (req, res, next) => {
  try {
    const refreshToken = typeof req.body.refresh_token === 'string'
      ? req.body.refresh_token
      : '';
    if (!refreshToken) {
      return res.status(400).json({ message: 'Thiếu refresh token.' });
    }
    const data = await supabaseAuth('token?grant_type=refresh_token', {
      body: { refresh_token: refreshToken },
    });
    return res.json({ user: data.user, session: data });
  } catch (error) {
    return res.status(error.status ?? 500).json({ message: error.message });
  }
});

router.post('/logout', async (req, res, next) => {
  try {
    const match = (req.headers.authorization ?? '').match(/^Bearer\s+(.+)$/i);
    if (!match) return res.status(401).json({ message: 'Thiếu access token.' });
    await supabaseAuth('logout', { accessToken: match[1] });
    return res.status(204).end();
  } catch (error) {
    return res.status(error.status ?? 500).json({ message: error.message });
  }
});

export default router;
