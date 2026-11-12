# Đề xuất migration database — chưa thực thi

**Trạng thái:** tài liệu đề xuất. Không sửa/chạy `supabase_schema.sql`, không kết nối database. Cần review và phê duyệt riêng trước migration.

## Mục tiêu

Đưa schema tương thích với Flutter domain và API REST đã chọn; giữ nguyên toàn bộ trường model. Supabase Auth tiếp tục là nguồn tài khoản, Express là cổng nghiệp vụ. Không có bảng mật khẩu.

## Đích schema đề xuất

### `public.dreams`

- `id uuid primary key default gen_random_uuid()`.
- `user_id uuid not null references auth.users(id) on delete cascade`.
- `title text not null`; `content text not null`; `emotion text not null`.
- `tags text[] not null default '{}'`.
- `clarity_score smallint not null default 3 check (clarity_score between 1 and 5)`.
- `is_lucid boolean not null default false`.
- `dream_date date not null`.
- `created_at timestamptz not null default now()`.
- Index đề xuất `(user_id, created_at desc)`; cân nhắc index `(user_id, dream_date desc)` cho history theo ngày.

### `public.sleep_records`

- `id uuid primary key default gen_random_uuid()`.
- `user_id uuid not null references auth.users(id) on delete cascade`.
- `start_time timestamptz not null`; `end_time timestamptz` (nullable chỉ khi nghiệp vụ cho phép draft server-side; bản đầu khuyến nghị chỉ lưu completed nên NOT NULL).
- `duration_minutes integer not null check (duration_minutes between 0 and 1440)` nếu chỉ completed records.
- `quality_score smallint` (quyết định nullable cần chốt), check `0..100` khi có giá trị.
- `deep_sleep_minutes`, `light_sleep_minutes`, `rem_sleep_minutes integer not null default 0 check >= 0`.
- `notes text not null default ''`.
- `created_at timestamptz not null default now()`.
- Check `end_time >= start_time`; cân nhắc `duration_minutes` consistency. Không áp constraint stage sum == duration đến khi thống nhất cách làm tròn/ước lượng.
- Index `(user_id, created_at desc)` và có thể `(user_id, start_time desc)`.

`UserModel.sleepGoalHours`, `notificationsEnabled`, `avatarUrl` hiện chưa có bảng/API đã xác nhận; không tự tạo profile/settings table trong migration này. Giữ cục bộ đến khi có yêu cầu sản phẩm.

## Đánh giá kiểu dữ liệu

- **ID:** đề xuất UUID cho cả hai bảng vì `user_id` đã UUID, khó đoán ID, đồng nhất với Supabase Auth và tránh int64/JS precision. Flutter giữ `String`; Node path validator dùng UUID. Hiện schema bigint nên đây là breaking contract.
- **Tags:** đề xuất PostgreSQL `text[]`; ánh xạ trực tiếp `List<String>`, hỗ trợ containment. JSONB hợp lý nếu tags sau này thành object có metadata, nhưng hiện chỉ là danh sách chuỗi và sẽ làm phức tạp contract.
- **Dream date:** đề xuất SQL `DATE` vì ngày nhật ký là ngày lịch; `TIMESTAMPTZ` chỉ khi sản phẩm yêu cầu chính xác giờ mơ. `created_at`, `start_time`, `end_time` là TIMESTAMPTZ UTC.
- **Sleep quality:** 0–100 thống nhất `SleepSessionModel`; schema/API hiện 1–10. Chất lượng là điểm đánh giá/ước lượng, không phải phép đo y tế.
- **Thời lượng/stages:** timestamps là dữ kiện thời điểm chuẩn UTC; duration/stage phút là số nguyên để truy vấn và hiển thị, cần validate. Stage hiện chỉ là tỷ lệ giả định.

## Tương thích dữ liệu hiện có và rủi ro migration

Schema được tạo `if not exists`; chạy lại file hiện tại không tự thêm/cập nhật cột mới cho bảng đã tồn tại. Migration phải có phiên bản riêng, backup và kiểm tra trước.

- `id bigint` → UUID: cần tạo ID UUID mới/column shadow, cập nhật khóa ngoại nếu có (hiện không thấy bảng liên quan), dual-read/write hoặc maintenance window, rồi đổi PK. Không cast bigint thành UUID.
- `dreams.tags text` → `text[]`: cần quyết định parse chuỗi cũ (chuỗi rỗng → `{}`, phân tách comma có thể làm hỏng tag chứa dấu phẩy). Cần export/đếm/kiểm tra trước; không tự đoán delimiter.
- Dreams thiếu `clarity_score`, `is_lucid`, `dream_date`: thêm cột nullable trước, backfill theo quy tắc được chấp thuận, kiểm tra, rồi mới thêm default/NOT NULL. Không thể suy ra chính xác dream_date từ created_at nếu người dùng tạo bản ghi trễ.
- Sleep hiện có `sleep_time`/`wake_time` kiểu text và `quality` 1–10, `note`. Chuyển timestamp phụ thuộc format/timezone lịch sử không được khai báo; cần inventory dữ liệu thực và chính sách diễn giải. Map quality tuyến tính sang 0–100 chỉ là biến đổi số học (ví dụ nhân 10), không tương đương đánh giá và cần quyết định sản phẩm.
- Không có model/storage đã biết cho dữ liệu sleep stages; thêm default 0 không tái tạo dữ liệu lịch sử.
- Đổi route/request contract cùng thời điểm có thể làm client cũ ngừng hoạt động. Ưu tiên API version/dual compatibility nếu app có bản phát hành ngoài.

## Trình tự migration đề xuất (chưa chạy)

1. Xác nhận decisions ở `DATA_CONTRACT.md`; kiểm kê schema/data thật, volume, constraints, indexes, RLS, consumers/backups trong môi trường có quyền.
2. Lưu backup và kiểm tra restore; tạo migration versioned cho staging, không chạy file schema destructive lặp lại.
3. Additive phase: thêm columns mới nullable/default an toàn; giữ cột cũ; tạo/backfill UUID và các fields theo mapping đã duyệt; log số lượng parse lỗi.
4. Validate counts, uniqueness, nulls, timestamps, quality range, tag mapping, owner/RLS. Chạy integration trên staging với fixture riêng.
5. Deploy API tương thích đọc cũ/mới; migrate client; theo dõi. Chỉ sau khi không còn consumer cũ mới chuyển PK/rename/drop cột trong migration riêng được phê duyệt.
6. Xác minh RLS/policies và grants sau thay đổi, kiểm tra account isolation; rollback plan phải dùng backup/dual columns, không giả định migration ngược không mất dữ liệu.

## RLS và quyền

Giữ RLS bật trên bảng. Policy cho authenticated owner `auth.uid() = user_id` cho select/insert/update/delete như hiện hành. Nếu Express tiếp tục dùng service-role, RLS bị bypass: mọi truy vấn phải lấy user từ JWT đã verify, ép `user_id` server-side và lọc cả mutation. Không cấp service-role cho Flutter. Xem xét dùng DB client theo JWT/RLS nếu thiết kế server được đổi sau này; đây không phải thay đổi trong đề xuất hiện tại.

## Chưa đủ thông tin để quyết định

- Có dữ liệu thật trong các bảng hiện hữu không, format timezone của sleep text là gì?
- Có app/backend client đã phát hành dùng bigint/legacy columns không?
- Chọn `end_time NOT NULL` và chỉ sync phiên hoàn tất hay cần draft đa thiết bị?
- `quality_score` nullable hay luôn bắt buộc; duration được client gửi hay server tính?
- Định dạng/tag delimiter dữ liệu cũ và có dấu phẩy bên trong tag không?

Không suy đoán các điểm này; cần inventory và quyết định trước khi viết migration executable.

