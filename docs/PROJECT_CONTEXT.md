# PROJECT_CONTEXT — Dream Diary

Ngày rà soát bổ sung: 2026-11-12. Phạm vi giai đoạn 2 là tài liệu thiết kế. Không đọc `.env`/`server/.env`, không gọi Supabase. GitHub chưa được đối chiếu; ghi nhận theo checkout local.

## Kiến trúc đã chọn
**Flutter → Node.js/Express REST API → Supabase PostgreSQL/Auth.** Flutter không dùng Supabase Flutter trực tiếp cho CRUD nghiệp vụ. Supabase Flutter vẫn đang được khai báo nhưng không được khởi tạo trong `main.dart`; có thể cần xem xét gỡ dependency ở nhiệm vụ implementation riêng, không phải hiện tại.

Flutter UI → Provider → service/repository → Dio API client. Express xác minh Supabase access token, lấy `req.user.id`, thực hiện truy vấn PostgreSQL theo owner. Auth endpoints của backend gọi Supabase Auth; service-role chỉ phía server. RLS bật làm lớp bảo vệ bổ sung, nhưng service-role bypass RLS nên owner filter ở server bắt buộc.

## Hiện trạng implementation (không thay đổi trong giai đoạn 2)
- Auth Flutter mock, SharedPreferences lưu user/token, forgot-password giả lập; `AuthProvider` nhận `UserModel`/bool, không biểu diễn pending confirmation.
- `ApiClient` URL mặc định cổng 5000 trong khi server port mặc định 3000; interceptor chưa gắn bearer.
- `ApiService` auth/dream/sleep vẫn mock/stub; CRUD app dùng repositories fixtures/in-memory.
- Backend hiện có auth register/login/refresh/logout; dreams CRUD; sleep-records CRUD; health; account data delete. Thiếu forgot/reset password.
- Server middleware gọi `authClient.auth.getUser(accessToken)`, sau đó route dùng service-role lọc `user_id`. Schema hiện RLS owner policies.

## Hợp đồng mục tiêu
Chi tiết đầy đủ ở `docs/DATA_CONTRACT.md`, endpoint ở `docs/API_SPECIFICATION.md`, migration ở `docs/DATABASE_MIGRATION_PROPOSAL.md`.

- `dreams`: UUID id/user; title/content/emotion; tags `text[]`; clarity 1..5; lucid boolean; `dream_date DATE`; `created_at TIMESTAMPTZ`.
- `sleep_records`: UUID id/user; start/end `TIMESTAMPTZ` UTC; duration minutes; quality 0..100; deep/light/REM minutes; notes; created_at. Khuyến nghị API chỉ nhận session đã hoàn tất ở bản đầu; active `isTracking` giữ local.
- User identity do Supabase Auth cấp UUID. `UserModel` có settings/avatar chưa có API/table; tiếp tục local cho tới khi có yêu cầu.
- API wire keys `snake_case`, Flutter property giữ camelCase; server sinh ID/owner/created timestamp.

## Mismatch chính được xác nhận
1. Dream schema id bigint; model ép id String. DB tags text nhưng Dart gửi list. DB/API thiếu dream_date, clarity_score, is_lucid.
2. Sleep schema/API dùng `sleep_time`, `wake_time`, quality 1..10, note; model dùng `startTime/endTime`, qualityScore 0..100, stages, notes. ID DB bigint, Dart String. `isTracking` là trạng thái local.
3. Auth API trả `{user, session}` với Supabase `access_token`/`refresh_token`; AuthService mock kỳ vọng `{user, token}`. Signup backend trả 202/session null khi confirmation required; provider không có trạng thái pending.
4. Forgot password chưa có backend route. Logout backend cần Bearer access token nhưng client chưa gọi. Refresh route tồn tại nhưng client không dùng.
5. Backend route sleep là `/sleep-records`, Flutter stub nhắc `/sleep-sessions`. URL/API port lệch.
6. GET list bản đầu thống nhất trả JSON array trực tiếp; chưa pagination envelope. Có thể mở rộng pagination sau bằng contract/version tương thích mới.

## Bảo mật/cấu hình
- Không mở file `.env` hay `server/.env`; `.env.example` root dùng placeholder. Server env example có tên biến đúng nhưng đã ghi nhận ở giai đoạn trước có Supabase project config cụ thể; phải thay placeholder trước chia sẻ.
- Root và server `.gitignore` hiện có ignore `.env`, `.env.*` và allowlist `.env.example`. Đây là kiểm tra tên/quy tắc, không kiểm tra giá trị thật.
- `CORS_ORIGIN` hiện mặc định `*`; nên đặt origin allowlist cho deploy. CORS không thay auth.
- API URL gợi ý: Android emulator `10.0.2.2:3000`; thiết bị thật LAN IP host; web/desktop cùng máy `localhost:3000`; production HTTPS.
- Không service-role key ở Flutter. SharedPreferences không phù hợp lưu refresh/access token nhạy cảm; secure storage/platform-specific web policy cần thiết kế trước tích hợp.

## Decisions còn mở
- DATE hay TIMESTAMPTZ cho dream date: đề xuất DATE.
- Chỉ sync session hoàn tất hay lưu active session đa thiết bị: đề xuất chỉ completed ở bản đầu.
- `quality_score` bắt buộc hay nullable; quy tắc floor duration đã thống nhất trong contract.
- Dữ liệu cũ có thật không, sleep text có timezone nào, tag delimiter là gì, consumer dùng bigint nào.
- Không còn mở: bản đầu trả list array; pagination có thể bổ sung sau.
- Profile/settings cần server-side hay tiếp tục local.

Không suy đoán thay chủ dự án. Xem migration proposal để biết các câu hỏi cần inventory/approval.

## Tài liệu và giới hạn kiểm tra
Giai đoạn 2 tạo `DATA_CONTRACT.md`, `API_SPECIFICATION.md`, `DATABASE_MIGRATION_PROPOSAL.md` và cập nhật context/plan/log. Chỉ rà soát tĩnh; không thực thi analyzer/test/server/migration trong nhiệm vụ này. Không thay đổi UI, app code, backend code, schema hay database.

## Cập nhật sau Đợt 8D.1 — 2026-11-13

- Flutter Authentication source nay gọi Express `/auth/login`, `/auth/register`, `/auth/refresh`, `/auth/logout`; token lưu bằng `flutter_secure_storage`. Auth restoration refresh token trước khi AuthRouteGuard phân loại trạng thái. Register session null được giữ unauthenticated/pending confirmation. Không có xác minh tài khoản thật trong test suite.
- ApiClient lấy access token qua callback và mặc định gắn Bearer cho request cần auth; login/register/refresh là public, logout cần Bearer. API base URL mặc định `localhost:3000/api`, override bằng `--dart-define=API_BASE_URL=...`.
- Forgot/reset email vẫn chưa hỗ trợ. Refresh hiện chạy khi khôi phục phiên lúc app mở và có thể retry thủ công sau lỗi mạng; chưa có auto-refresh/replay cho 401 phát sinh giữa phiên.
- Dream/Sleep CRUD Flutter vẫn fixtures/stub. Không dùng Supabase Flutter cho auth hoặc CRUD; không xác minh end-to-end với user thật trong Đợt 8D.1.

## C?p nh?t sau ??t 8D.2 ? 2026-11-13

- ApiClient refresh access token khi request c?n Bearer nh?n 401; login/register/refresh b? lo?i kh?i lu?ng interceptor. Request g?c ???c replay t?i ?a m?t l?n v?i method, URL, query, body v? c?u h?nh c?n l?i ???c gi? t? RequestOptions.
- AuthService d?ng single-flight refresh. N?u m?t 401 ??n sau khi token ?? ???c xoay, request ???c retry tr?c ti?p b?ng access token m?i nh?t thay v? t?o refresh th? hai. Refresh l?i s? x?a phi?n c?c b? trong secure storage, th?ng b?o AuthProvider unauthenticated v? k?ch ho?t route guard. L?i refresh kh?ng treo request.
- C?c test d?ng fake Dio adapter, Auth API v? token storage; kh?ng d?ng t?i kho?n th?t. Dream/Sleep CRUD v?n ch?a t?ch h?p.
