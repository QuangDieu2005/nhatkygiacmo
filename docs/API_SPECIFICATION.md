# API Specification — Dream Diary

**Trạng thái:** Hợp đồng source code được chuẩn hóa ở Đợt 8A.2; chưa kết nối Supabase thật. Schema SQL hiện tại vẫn là schema legacy và cần migration được phê duyệt trước khi chạy routes nghiệp vụ với database thật.

**Base URL:** `{API_BASE_URL}` trỏ tới origin backend, ví dụ `http://<host>:3000/api`. API hiện không dùng pagination envelope: GET list trả JSON array trực tiếp; có thể mở rộng pagination bằng thay đổi contract/version tương thích sau này.

## Quy ước chung

- API nghiệp vụ yêu cầu `Authorization: Bearer <Supabase access_token>` qua Express middleware xác minh token với Supabase Auth.
- Owner chỉ lấy từ `req.user.id` của JWT đã xác minh. Body `user_id` bị từ chối; mọi GET/update/delete đều có filter owner.
- Record ID trên path và DTO là UUID dạng chuỗi. Server/database sinh ID và `created_at`; client không được ghi các trường này.
- Request body không nhận field ngoài contract, bao gồm `id`, `user_id`, `created_at`, `duration_minutes`, `isTracking`/`is_tracking`.
- Lỗi dùng `{ "message": string, "code": string }`. Validation/path lỗi trả 400; thiếu hoặc sai token 401; record không tồn tại/không thuộc user 404; lỗi nội bộ trả thông báo chung 500 `INTERNAL_ERROR`, không trả lỗi Supabase hoặc stack.

## Authentication

Auth routes giữ nguyên trong Đợt 8A.2.

| Method + URL | Request | Response thành công | Auth | Lỗi dự kiến |
|---|---|---|---|---|
| POST `/auth/register` | `{ "email": string, "password": string, "name": string }` | `201 { user, session, confirmation_required:false }` nếu có session; `202 { user|null, session:null, confirmation_required:true }` nếu cần email confirmation | Không | 400, 409 hoặc upstream 400, 429, 502/503 |
| POST `/auth/login` | `{ "email": string, "password": string }` | `200 { user, session }` | Không | 400, 401, 429, 502/503 |
| POST `/auth/refresh` | `{ "refresh_token": string }` | `200 { user, session }` với session mới | Không | 400, 401, 429, 502/503 |
| POST `/auth/logout` | Không có body | `204` | Bearer access token | 401, 429, 502/503 |
| POST `/auth/forgot-password` | `{ "email": string }` | `202 { "message": string }` (đề xuất; chưa triển khai) | Không | 400, 429, 502/503 |
| POST `/auth/reset-password` | Recovery credential theo flow được chọn (đề xuất; chưa triển khai) | `200 { "message": string }` | Recovery credential | 400, 401, 429, 502/503 |

`SessionDTO` dùng các key Supabase: `access_token`, `refresh_token`, `token_type`, `expires_in`, `expires_at`. `UserDTO` tối thiểu gồm `id`, `email`, `name`, `avatar_url`, `created_at`. Flutter phải coi register `session:null` là unauthenticated/pending confirmation, không lưu token và không vào main shell.

## Dreams

| Method + URL | Request | Response | Auth | Lỗi dự kiến |
|---|---|---|---|---|
| GET `/dreams` | Query tùy chọn: `q` (tìm title/content), `emotion`, `tag` (khớp chính xác một tag), `from`/`to` (`YYYY-MM-DD`) | `200 [DreamDTO, ...]`; rỗng là `[]` | Có | 400 query sai, 401, 429, 500/503 |
| POST `/dreams` | `{title, content, emotion, tags?, clarity_score?, is_lucid?, dream_date}`; `tags` là `string[]`, `clarity_score` 1–5, `is_lucid` boolean | `201 DreamDTO` | Có | 400 validation/field không cho phép, 401, 429, 500/503 |
| PATCH `/dreams/:id` | UUID path; cùng write fields POST. Đây là update payload đầy đủ; optional fields bỏ qua sẽ nhận default | `200 DreamDTO` | Có | 400 UUID/validation, 401, 404, 429, 500/503 |
| DELETE `/dreams/:id` | UUID path | `204` | Có | 400 UUID, 401, 404, 429, 500/503 |

Write DTO có `title`, `content`, `emotion`, `tags`, `clarity_score`, `is_lucid`, `dream_date`. Defaults: `tags: []`, `clarity_score: 3`, `is_lucid: false`; `title`, `content`, `emotion`, `dream_date` bắt buộc. `emotion` phải thuộc các giá trị `happy`, `peaceful`, `excited`, `sad`, `scared`, `confused`, `neutral`. `dream_date` là ngày lịch đúng `YYYY-MM-DD`, không parse qua timezone.

Response DTO gồm `id`, `user_id`, tất cả writable fields và `created_at`. `id`/`user_id` phải là UUID; `created_at` là timestamp ISO-8601 có timezone. Query `tag` dùng PostgreSQL `text[]` containment (`.contains('tags', [tag])`/PostgREST `cs`). Query `q` chỉ tìm title/content; không dùng `tags.ilike`.

## Sleep records

| Method + URL | Request | Response | Auth | Lỗi dự kiến |
|---|---|---|---|---|
| GET `/sleep-records` | Query tùy chọn `days` (1–3650), hoặc `from`/`to` (`YYYY-MM-DD`) | `200 [SleepRecordDTO, ...]`; rỗng là `[]` | Có | 400 query sai, 401, 429, 500/503 |
| POST `/sleep-records` | `{start_time, end_time, quality_score, deep_sleep_minutes?, light_sleep_minutes?, rem_sleep_minutes?, notes?}` | `201 SleepRecordDTO` | Có | 400 timestamp/field/range không hợp lệ, 401, 429, 500/503 |
| PATCH `/sleep-records/:id` | UUID path; cùng full write fields như POST | `200 SleepRecordDTO` | Có | 400 UUID/validation, 401, 404, 429, 500/503 |
| DELETE `/sleep-records/:id` | UUID path | `204` | Có | 400 UUID, 401, 404, 429, 500/503 |

`start_time` và `end_time` bắt buộc là ISO-8601 có `Z` hoặc UTC offset. Express validate calendar/time, chuẩn hóa hai giá trị về UTC, yêu cầu `end_time > start_time` và elapsed không quá 24 giờ. Express tính `duration_minutes = floor(elapsed milliseconds / 60000)`; khoảng dương dưới một phút cho kết quả 0. Request có `duration_minutes` hoặc `isTracking`/`is_tracking` bị từ chối. Timestamp thiếu timezone không được diễn giải theo timezone máy chủ.

`quality_score` bắt buộc là số nguyên 0–100 theo domain model hiện có. Stage minutes là số nguyên không âm, mặc định 0. `notes` là chuỗi hoặc null; khi ghi DB null được chuẩn hóa thành chuỗi rỗng. `id`, `user_id`, `duration_minutes`, `created_at` và trạng thái tracking không thuộc write DTO. Response DTO đầy đủ gồm các trường trên, cộng `id`, `user_id`, `duration_minutes`, `created_at`; API chỉ chứa phiên đã hoàn tất (`end_time` không null), và `isTracking` không xuất hiện.

## Health và các endpoint khác

| Method + URL | Thành công | Auth | Lỗi |
|---|---|---|---|
| GET `/health` (đường dẫn đầy đủ `/api/health`) | `200 {status:"ok", service:"dream-diary-api", database:"connected"}` | Không | `503 {status:"degraded", database:"unavailable", code:"DEPENDENCY_UNAVAILABLE"}` |
| DELETE `/account/data` (đường dẫn đầy đủ `/api/account/data`) | Xóa dreams/sleep rows thuộc user hiện tại | Có | 401, lỗi chung; endpoint hiện không atomic và chưa được Flutter dùng |

## Ghi chú tương thích source và database

- Flutter `DreamModel` và `SleepSessionModel` giữ `toJson/fromJson` cho local/mock và pending sleep snapshot. API dùng `toApiWriteJson/fromApiJson` riêng; API parser yêu cầu trường bắt buộc đúng kiểu, UUID hợp lệ, date-only không timezone và timestamp có timezone.
- Express dream/sleep routes đã được chuẩn hóa theo endpoint, field, UUID, filter owner, array containment, duration server-side và error DTO trong source code. Chúng được inject database client nhưng chưa gọi hoặc kiểm thử với Supabase thật.
- `supabase_schema.sql` hiện vẫn dùng bigint, `tags text`, dream thiếu fields mới và sleep có legacy `sleep_time/wake_time/quality/note`; source routes chưa thể chạy với schema này trước khi migration được review/áp dụng riêng.
- Android emulator thường dùng `http://10.0.2.2:3000/api`; thiết bị thật dùng LAN host IP; production dùng HTTPS. CORS allowlist và cấu hình môi trường deploy phải được chốt trước phát hành. Không đưa service-role key vào Flutter.
