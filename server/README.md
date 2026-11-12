# Dream Diary Express API

Backend REST API cho ứng dụng Flutter Dream Diary. Supabase Auth vẫn xác thực email/mật khẩu; Flutter gửi access token JWT đến API. Server xác minh token, sau đó truy vấn PostgreSQL theo đúng `user_id`.

## Yêu cầu
- Node.js 20 trở lên
- Project Supabase đã tạo và đã chạy `../supabase_schema.sql` trong SQL Editor

## Cài đặt
```bash
cd server
npm install
cp .env.example .env
```
Mở `server/.env` và điền:
- `SUPABASE_URL`: Project URL
- `SUPABASE_ANON_KEY`: Publishable key (hoặc legacy anon public key) dùng để xác minh JWT
- `SUPABASE_SERVICE_ROLE_KEY`: Secret/service_role key lấy từ Supabase Dashboard. Chỉ lưu ở server, tuyệt đối không đưa vào Flutter, Git hoặc chia sẻ công khai.

## Chạy server trên Windows
1. Chạy `setup_windows.bat` một lần để cài package và tạo `server/.env`.
2. Điền các giá trị Supabase vào `server/.env`.
3. Chạy `start_windows.bat` để bật server.

Hoặc chạy thủ công:
```bash
npm run dev
# hoặc
npm start
```
Mở `http://localhost:3000/api/health`; kết quả mong đợi có `status: ok` và `database: connected`.

## API endpoints
Tất cả endpoint trừ health cần header `Authorization: Bearer <Supabase access_token>`.

| Method | Endpoint | Mô tả |
|---|---|---|
| GET | `/api/health` | Kiểm tra server/database |
| GET | `/api/dreams?q=&emotion=` | Danh sách/tìm kiếm giấc mơ |
| POST | `/api/dreams` | Tạo giấc mơ |
| PATCH | `/api/dreams/:id` | Cập nhật giấc mơ |
| DELETE | `/api/dreams/:id` | Xóa giấc mơ |
| GET | `/api/sleep-records?days=90` | Danh sách giấc ngủ |
| POST | `/api/sleep-records` | Tạo bản ghi giấc ngủ |
| PATCH | `/api/sleep-records/:id` | Cập nhật bản ghi |
| DELETE | `/api/sleep-records/:id` | Xóa bản ghi |
| DELETE | `/api/account/data` | Xóa toàn bộ dữ liệu cá nhân |

Server không nhận `user_id` từ request body; ID luôn lấy từ JWT đã xác minh. Dù dùng service role để truy vấn, mọi truy vấn dữ liệu cá nhân đều lọc theo `user_id` của người đăng nhập.

## Kết nối Flutter
Trong file `.env` ở thư mục gốc Flutter, điền `SUPABASE_URL`, `SUPABASE_ANON_KEY` và `API_BASE_URL`.
- Android Emulator: `http://10.0.2.2:3000/api`
- Flutter Web/Windows chạy cùng máy: `http://localhost:3000/api`
- Điện thoại thật: `http://IP_LAN_CUA_MAY_TINH:3000/api` (điện thoại và máy tính cùng Wi-Fi; cho phép Node.js qua Windows Firewall).

Chạy server trước, sau đó ở thư mục gốc Flutter:
```bash
flutter pub get
flutter run
```

## Bảo mật triển khai
- Không commit `server/.env`; không chia sẻ service role key.
- Đổi `CORS_ORIGIN=*` thành domain cụ thể khi triển khai web production.
- Dùng HTTPS khi deploy server ra Internet.
- RLS vẫn nên bật trên các bảng; service role bypass RLS nên backend bắt buộc xác minh JWT và lọc `user_id`.
