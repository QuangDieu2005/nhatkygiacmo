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

## Update after Sprint 8D.2 (2026-11-13)

- ApiClient refreshes an access token for protected requests receiving HTTP 401; login/register/refresh are excluded. The original request is replayed at most once with its method, URL, query, body, and Dio configuration preserved.
- AuthService uses single-flight refresh. A delayed 401 uses the latest rotated token rather than starting a second refresh. Any refresh failure clears the local secure session, marks AuthProvider unauthenticated, and notifies the route guard.
- Tests use a fake Dio adapter, fake Auth API, and fake token storage. Dream/Sleep CRUD is not yet integrated.

## Supabase connection status (2026-11-13)

- Express uses Supabase Auth and its server-side database client. A read-only schema probe against the configured project confirmed that Dream/Sleep CRUD repositories in Flutter still use local fixture data.
- The live `dreams` table is missing `clarity_score`, `is_lucid`, and `dream_date`. The live `sleep_records` table is missing `start_time`, `end_time`, `quality_score`, all three sleep-stage minute fields, and `notes`. Existing routes query these contract fields, so Dream/Sleep CRUD cannot be enabled safely until schema compatibility is resolved.
- No rows were fetched and no database changes were made. Migration remains gated on approved mapping decisions, backup/restore rehearsal, and explicit approval.

## Cập nhật sau Đợt 8E.1 — 2026-11-13

- `docs/SUPABASE_MIGRATION_PLAN.md` phân biệt schema tham chiếu trong repository với cột đã probe trên project live. Probe chỉ xác nhận sự hiện diện cột, không xác minh type, constraint, RLS/policy/grant hoặc row data.
- Migration proposal ưu tiên bảo toàn: giữ legacy tables/raw values, dùng UUID mapping riêng thay vì cast ID, không drop/rename trong đợt đầu, giữ trạng thái unresolved cho tags/date/timezone/quality/stages chưa ánh xạ.
- `docs/8E_MIGRATION_DECISIONS.md` liệt kê quyết định đã chốt, câu hỏi còn thiếu, yêu cầu backup/restore, staging, rollback và cổng phê duyệt.
- Chưa tạo SQL executable, không chạy query ghi, migration hoặc backup/restore; chưa sửa Flutter/Express/API/schema/database.
