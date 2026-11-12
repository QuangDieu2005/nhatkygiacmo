# Dream Diary - Flutter + Express + Supabase

## Cấu trúc
- `lib/`: ứng dụng Flutter. Auth dùng Supabase Auth; CRUD dữ liệu đi qua Express API.
- `server/`: Node.js + Express REST API.
- `supabase_schema.sql`: tạo bảng dreams, sleep_records và chính sách RLS.
- `.env`: cấu hình public cho Flutter (không chứa service role key).
- `server/.env`: cấu hình bí mật chỉ dành cho server; tự tạo từ `server/.env.example`.

## Khởi chạy lần đầu
1. Tạo Supabase Project.
2. Chạy toàn bộ `supabase_schema.sql` trong Supabase SQL Editor.
3. Điền URL và Publishable key vào `.env` ở thư mục gốc.
4. Tạo `server/.env` từ `server/.env.example`; điền URL, Publishable/anon key và service_role/secret key.
5. Terminal 1: `cd server`, `npm install`, `npm run dev`.
6. Terminal 2 tại thư mục gốc: `flutter pub get`, `flutter run`.

Xem `server/README.md` để biết endpoint, cấu hình IP Android và hướng dẫn bảo mật.
