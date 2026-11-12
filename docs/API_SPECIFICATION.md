# API Specification — hợp đồng mục tiêu

**Base URL:** `{API_BASE_URL}` trỏ tới origin backend, ví dụ `http://<host>:3000/api`. Các response thành công dùng JSON trừ khi ghi 204. Đây là đặc tả đề xuất theo `DATA_CONTRACT.md`; backend hiện chưa triển khai toàn bộ hợp đồng. Không đồng nghĩa endpoint đã được kiểm thử.

## Quy ước bảo vệ

- Auth routes nhận HTTPS trong môi trường deploy. Dream/sleep cần `Authorization: Bearer <access_token>`.
- Express xác minh token với Supabase Auth (`auth.getUser(token)` như middleware hiện tại). Mọi truy vấn dùng `req.user.id`; bỏ qua/reject `user_id` do body cung cấp. UUID record không được dùng thay kiểm tra owner.
- Response lỗi chuẩn: `{ "message": "...", "code": "..." }`. Mã chung: 400 validation, 401 token thiếu/hết hạn/không hợp lệ, 403 cấm, 404 không tồn tại hoặc không thuộc user, 409 conflict nếu có, 429 rate limit, 500 lỗi nội bộ, 502/503 phụ thuộc dịch vụ upstream.

## Auth

| Method + URL | Body | Thành công | Auth | Lỗi dự kiến |
|---|---|---|---|---|
| POST `/auth/register` | `{ "email": string, "password": string, "name": string }` | `201` nếu session có: `{ "user": UserDTO, "session": SessionDTO, "confirmation_required": false }`; `202` nếu cần email confirm: `{ "user": UserDTO|null, "session": null, "confirmation_required": true }` | Không | 400 validation, 409 email đã dùng (hoặc 400 từ upstream theo chuẩn hóa), 429, 502/503 |
| POST `/auth/login` | `{ "email": string, "password": string }` | `200 { "user": UserDTO, "session": SessionDTO, "confirmation_required": false }` | Không | 400, 401 thông tin sai/chưa xác nhận (phân biệt theo chính sách không tiết lộ email tồn tại), 429, 502/503 |
| POST `/auth/refresh` | `{ "refresh_token": string }` | `200 { "user": UserDTO, "session": SessionDTO }` (token mới; thay toàn bộ session cũ) | Không; refresh token trong body | 400, 401/400 refresh bị thu hồi/hết hạn, 429, 502/503 |
| POST `/auth/logout` | không có | `204` | Có; Bearer access token | 401, 429, 502/503 |
| POST `/auth/forgot-password` **đề xuất mới** | `{ "email": string }` | `202 { "message": "Nếu địa chỉ hợp lệ, hướng dẫn sẽ được gửi." }` | Không | 400, 429, 502/503; response không tiết lộ email có tài khoản |
| POST `/auth/reset-password` **đề xuất mới** | `{ "access_token": string, "new_password": string }` hoặc code một lần đã đổi thành session/token theo flow Supabase được chọn | `200 { "message": "Mật khẩu đã được cập nhật." }` | Xác thực bằng recovery credential; flow phải chốt | 400, 401, 429, 502/503 |

`UserDTO` tối thiểu: `{ "id": UUID, "email": string, "name": string|null, "avatar_url": string|null, "created_at": timestamp }`. `SessionDTO`: `{ "access_token": string, "refresh_token": string, "token_type": "bearer", "expires_in": number, "expires_at": number|null }`.

**Session null khi đăng ký:** `202` không phải đăng nhập thành công. Flutter giữ trạng thái unauthenticated/pending confirmation, hiển thị thông báo hướng dẫn xác nhận, không lưu token, không vào main shell; người dùng đăng nhập sau khi xác nhận. `user` null vẫn phải được xử lý an toàn. Nếu `session != null`, coi là authenticated và lưu session đầy đủ an toàn.

**Khôi phục session:** Flutter đọc session đã lưu trong secure storage; nếu access token gần/hết hạn, gọi `/auth/refresh` một lần có khóa đồng thời, thay access + refresh token nguyên tử. Nếu refresh lỗi 401, xóa session và quay về unauthenticated. Mọi request nghiệp vụ dùng access token mới nhất; nếu nhận 401 do hết hạn, refresh một lần rồi retry tối đa một lần. Không retry lỗi 403/validation. Lưu token trong SharedPreferences hiện tại không đủ bảo vệ; chọn secure storage theo nền tảng. Web cần lựa chọn riêng (BFF/HttpOnly cookie hoặc storage threat model được phê duyệt), không giả định plugin native áp dụng như nhau.

## Dreams CRUD

| Method + URL | Request | Response | Auth | Lỗi dự kiến |
|---|---|---|---|---|
| GET `/dreams` | query tùy chọn: `q`, `emotion`, `from`/`to` (`YYYY-MM-DD`), `limit`, `cursor` | `200 { "items": [DreamDTO], "next_cursor": string|null }` (hoặc list nếu chốt giản lược; hiện server trả list) | Có | 400 query sai, 401, 429, 500/503 |
| POST `/dreams` | `{ "title": string, "content": string, "emotion": EmotionType.name, "tags": string[], "clarity_score": 1..5, "is_lucid": boolean, "dream_date": "YYYY-MM-DD" }` | `201 DreamDTO` | Có | 400 validation, 401, 429, 500/503 |
| PATCH `/dreams/:id` | UUID path; toàn bộ writable fields theo đề xuất (partial semantics cần xác nhận) | `200 DreamDTO` | Có | 400 UUID/validation, 401, 404, 429, 500/503 |
| DELETE `/dreams/:id` | UUID path | `204` | Có | 400 UUID, 401, 404, 429, 500/503 |

`DreamDTO`: đầy đủ `id`, `user_id`, `title`, `content`, `emotion`, `tags`, `clarity_score`, `is_lucid`, `dream_date`, `created_at` theo DATA_CONTRACT. Không chấp nhận client ghi `user_id`.

## Sleep records CRUD

| Method + URL | Request | Response | Auth | Lỗi dự kiến |
|---|---|---|---|---|
| GET `/sleep-records` | query tùy chọn `days` (1..3650), `from`, `to`, phân trang | `200 { "items": [SleepRecordDTO], "next_cursor": string|null }` (hiện server trả list; cần chốt) | Có | 400, 401, 429, 500/503 |
| POST `/sleep-records` | `{ "start_time": ISO-8601 UTC, "end_time": ISO-8601 UTC, "duration_minutes": integer, "quality_score": 0..100|null, "deep_sleep_minutes": integer, "light_sleep_minutes": integer, "rem_sleep_minutes": integer, "notes": string|null }` | `201 SleepRecordDTO` | Có | 400 timestamp/constraint, 401, 429, 500/503 |
| PATCH `/sleep-records/:id` | UUID path; trường writable đầy đủ (hoặc partial sau khi chốt) | `200 SleepRecordDTO` | Có | 400, 401, 404, 429, 500/503 |
| DELETE `/sleep-records/:id` | UUID path | `204` | Có | 400 UUID, 401, 404, 429, 500/503 |

`SleepRecordDTO`: `id`, `user_id`, `start_time`, `end_time`, `duration_minutes`, `quality_score`, `deep_sleep_minutes`, `light_sleep_minutes`, `rem_sleep_minutes`, `notes`, `created_at`. Bản ghi API là session đã kết thúc; `isTracking` không xuất hiện.

## Health

| Method + URL | Request | Response | Auth | Lỗi dự kiến |
|---|---|---|---|---|
| GET `/health` (public, base path `/api`) | none | `200 { "status": "ok", "service": "dream-diary-api", "database": "connected" }` | Không | `503 { "status": "degraded", "database": "unavailable" }` |

## Endpoint hiện có khác

`DELETE /api/account/data` hiện xóa dream/sleep rows cho user sau auth, nhưng chưa nằm trong mục tiêu CRUD thông thường. Giữ lại trong backend hiện tại; nếu đưa vào client cần xác nhận UX, re-authentication, transaction/atomicity và semantics (không xóa tài khoản Supabase). Không nhầm với endpoint xóa account.

## Endpoint và hợp đồng hiện trạng cần sửa trong bước triển khai

Auth backend trả `{user, session}`; `AuthService` hiện giả định `{user, token}`. `ApiClient` chưa gắn JWT. Forgot-password route chưa có. Dreams backend chỉ nhận `title/content/emotion/tags`; sleep backend dùng `sleep_time/wake_time/quality/note`; id route parse bigint. Các điểm này chưa đáp ứng spec. Chi tiết thay đổi DB chỉ trong `DATABASE_MIGRATION_PROPOSAL.md`.

## CORS và URL môi trường

- Android Emulator truy cập máy host thường dùng `http://10.0.2.2:3000/api`; thiết bị thật dùng `http://<LAN-IP-host>:3000/api` và cùng mạng/firewall; web/desktop cùng host có thể dùng `http://localhost:3000/api`.
- Production dùng HTTPS URL triển khai. Không nhúng private service key trong app.
- `CORS_ORIGIN` phải là danh sách origin chính xác, theo môi trường; `*` hiện backend chấp nhận mọi origin. CORS không thay thế auth.
- Không đọc file `.env` thật. Root `.gitignore` và `server/.gitignore` ignore env files và allowlist `.env.example`; server example keys hiện có tên biến phù hợp nhưng config mẫu từng chứa project value cụ thể (đã được ghi nhận ở context), phải thay bằng placeholder trước khi commit/chia sẻ.
