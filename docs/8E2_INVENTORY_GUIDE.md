# Hướng dẫn inventory Supabase chỉ đọc — Đợt 8E.2

## Mục đích và trạng thái

`docs/8E_READ_ONLY_INVENTORY.sql` là bộ truy vấn để **chủ dự án tự review và chạy thủ công** trong Supabase SQL Editor. Agent chưa chạy các truy vấn này. Inventory live 8E.1 chỉ xác nhận sự hiện diện cột bằng REST; kiểu dữ liệu, constraints, indexes, triggers, RLS/grants và row counts vẫn đang chờ xác minh.

File SQL chỉ có câu `SELECT` và comment; không có migration, DDL, `INSERT`, `UPDATE`, `DELETE`, `UPSERT` hoặc RPC. Nó không chọn row-level content, tags, notes, dream titles/content, sleep timestamps, email hay UUID user. Nhóm cuối chỉ trả tên bảng và tổng `COUNT(*)`.

## Cách chạy trong Supabase SQL Editor

1. Xác minh đúng project/environment trong Supabase Dashboard trước khi mở SQL Editor. Không gửi project URL, key hay token vào tài liệu/chat.
2. Mở `docs/8E_READ_ONLY_INVENTORY.sql` trong repository và review nội dung.
3. Chạy **từng statement/nhóm riêng lẻ**, lần lượt theo các comment `Group 1A` đến `Group 6`. Chọn đúng statement rồi bấm Run; không chạy bất kỳ câu lệnh nào khác.
4. Lưu kết quả theo đúng nhóm và báo nếu có permission/catalog error. Lỗi truy vấn không có nghĩa là object không tồn tại.
5. `Group 6` đếm toàn bộ rows và có thể tốn thời gian trên bảng lớn. Chỉ chạy nếu chủ dự án chấp nhận tải đọc; nếu bảng không tồn tại hoặc role/RLS không cho phép, ghi “không chạy được” thay vì sửa schema.
6. Nếu catalog query bị từ chối hoặc output rỗng bất thường, dừng và nhờ project owner chạy bằng role được phép đọc catalog. Không thay bằng truy vấn phỏng đoán và không cấp thêm grants chỉ để chạy inventory.

## Cách đọc kết quả

- Kết quả Group 1/5 và các catalog groups là **metadata live tại thời điểm chạy**; ghi thời điểm và environment. Chúng không tự động sửa hoặc thay thế `supabase_schema.sql`.
- `supabase_schema.sql` là **schema tham chiếu trong repository**. So sánh hai nguồn thành từng khác biệt; không coi nội dung repository là bằng chứng live.
- Cột không xuất hiện ở Group 1/5 có thể do cột không tồn tại, object/schema sai, quyền metadata hạn chế hoặc query lỗi. Chỉ kết luận “không tồn tại” khi query chạy thành công và scope đúng.
- Group 2 trả constraint definitions từ PostgreSQL catalogs và FK delete action; nếu bị từ chối, FK/cascade chưa được xác minh.
- Group 3A/3B trả indexes và triggers trên bảng. Group 3C chỉ tìm dependency được catalog ghi nhận trực tiếp; PostgreSQL không ghi nhận mọi table reference trong mọi procedural function body. Kết quả rỗng không chứng minh không có function phụ thuộc. Body function được cố ý loại khỏi output.
- Group 4A/B/C cho biết RLS flags, policy definitions và explicit grants nhìn thấy qua views. Quyền inherited/indirect có thể cần kiểm tra thêm bởi owner. Không suy luận rằng RLS an toàn chỉ vì policy query rỗng.
- Group 6 là aggregate. COUNT có thể bị RLS/current role giới hạn, và số đếm chính xác có thể cần đọc/scanning bảng. Ghi role/context và không chia sẻ user identifiers.

## Kết quả cần gửi lại để tiếp tục mapping

Chia sẻ các output metadata sau, sau khi rà soát và che thông tin nhạy cảm:

1. Group 1A/1B: tên cột, type, nullable, default, identity/generated của `dreams`/`sleep_records`.
2. Group 2: PK/FK/unique/check definitions và `ON DELETE`.
3. Group 3A/3B/3C: index definitions, trigger/function names và function metadata; ghi rõ group nào bị permission error hoặc trả rỗng.
4. Group 4A/4B/4C: RLS enabled/forced, policies và grants. Cần giữ các role chuẩn (`anon`, `authenticated`, `service_role`) để review quyền; có thể alias custom role names nhất quán nếu chúng nhạy cảm.
5. Group 5: xác nhận presence/type/null/default của legacy fields `sleep_time`, `wake_time`, `quality`, `note` và target fields.
6. Group 6: tổng số rows cho mỗi bảng, hoặc ghi không chạy/không đủ quyền; không gửi row data.

Không gửi sample rows để giải thích delimiter/timezone. Mapping cần evidence được chuẩn bị riêng từ bản backup có quyền hạn chế, không đưa values cá nhân vào chat/repository.

## Che thông tin trước khi chia sẻ

- Xóa project URL/ref, organization name, email, access/refresh token, API key, database password và mọi secret khỏi ảnh/chữ.
- Không chụp hoặc dán records, dream text, notes, tags, sleep time, user ID hoặc email. SQL trong bộ này không yêu cầu các giá trị đó.
- Giữ tên bảng/cột, type, constraint/index/policy definitions và standard role names cần thiết; nếu custom role/object name nhạy cảm, thay bằng alias ổn định (`custom_role_1`) trên toàn bộ output.
- Nếu policy/check/function metadata vô tình chứa literal nhạy cảm, che literal đó nhưng giữ loại điều kiện và cấu trúc cần review. Không gửi function body.

## Mapping còn chờ bằng chứng/quyết định

- Không chọn delimiter/escaping cho `tags`.
- Không suy `dream_date` từ `created_at`.
- Không suy timezone/DST từ `sleep_time`/`wake_time`.
- Không chuyển `quality` sang 0–100 nếu chưa có semantics và công thức được duyệt.
- Không tạo sleep stage values.
- Không cast legacy ID sang UUID; cần type/FK/consumer inventory và UUID mapping decision.
- Không chạy migration/backfill hoặc cutover trước backup + restore rehearsal, staging reconciliation, mapping approvals và phê duyệt thực thi riêng.

## Cập nhật theo kết quả Đợt 8E.3

Chủ dự án đã cung cấp kết quả inventory live gồm column types/constraints, FK cascade, RLS/policies, indexes, triggers/function dependency và COUNT snapshot 0/0. Agent không chạy lại SQL. Hãy xem `docs/SUPABASE_MIGRATION_PLAN.md` và `docs/8E_MIGRATION_DECISIONS.md` để biết cách sử dụng snapshot này; trước migration vẫn phải recheck drift và row counts.
