# Đợt 8E — Các quyết định migration Supabase

**Mục đích:** ghi lại quyết định đã có và các câu hỏi cần trả lời trước khi thay đổi schema/dữ liệu. Tài liệu này không phải phê duyệt chạy migration và không chứa SQL thực thi.

## 1. Đã chốt

| Quyết định | Trạng thái | Ảnh hưởng |
|---|---|---|
| Bảo toàn dữ liệu cũ và duy trì khả năng khôi phục là ưu tiên cao nhất. | Đã chốt cho Đợt 8E.1 | Giữ bảng/cột/raw values và backup; không drop, rename hoặc cleanup trong đợt đầu. |
| Kiến trúc nghiệp vụ là Flutter → Express REST API → Supabase. | Đã chốt | Không dùng Supabase Flutter trực tiếp cho CRUD. |
| Hợp đồng đích dùng UUID cho record ID/owner; API Express lấy owner từ JWT đã xác minh. | Đã chốt trong contract | Legacy ID không cast sang UUID; cần mapping riêng sau khi type/key live được xác minh. |
| Đích Dream dùng tags `text[]` và ngày `DATE`; Sleep dùng UTC timestamps, quality 0–100, stage-minute fields. | Đã chốt trong contract, chưa phải mapping legacy | Chỉ áp dụng cho target data sau phê duyệt; không suy diễn legacy values. |
| Duration Sleep do Express tính từ start/end; client không được làm nguồn chuẩn cho duration. | Đã chốt trong contract | Existing `duration_minutes` được giữ nguyên để đối chiếu; semantics/type live vẫn cần xác minh. |
| Live schema probes chỉ kiểm tra cột và không lấy row. | Đã thực hiện | Không chứng minh types, constraints, RLS, grants, indexes, row counts hoặc data distributions. |

## 2. Hiện trạng live đã xác minh và giới hạn

Theo mục “Supabase connection investigation” trong `docs/TASK_LOG.md`, truy vấn metadata `SELECT column LIMIT 0` cho thấy:

- `dreams` hiện diện: `id`, `user_id`, `title`, `content`, `emotion`, `tags`, `created_at`; thiếu `clarity_score`, `is_lucid`, `dream_date`.
- `sleep_records` hiện diện: `id`, `user_id`, `duration_minutes`, `created_at`; thiếu `start_time`, `end_time`, `quality_score`, `deep_sleep_minutes`, `light_sleep_minutes`, `rem_sleep_minutes`, `notes`.
- Probe không xác minh kiểu dữ liệu/nullability/default/constraints hoặc các legacy sleep fields. Những gì `supabase_schema.sql` khai báo chỉ là schema tham chiếu trong repo, không phải xác nhận live.

## 3. Quyết định còn thiếu và tác động

| Câu hỏi cần quyết định | Lựa chọn / dữ liệu cần có | Tác động nếu chọn | Trạng thái |
|---|---|---|---|
| Project/environment nào sẽ là đích? | Xác nhận rõ dev/staging/production và project ref qua kênh an toàn; không ghi secret vào repo/docs. | Sai project có thể làm gián đoạn dữ liệu thật; quyết định backup/approval khác nhau theo môi trường. | Chờ xác nhận trước migration. |
| Primary strategy cho ID là gì? | Ưu tiên cấp UUID mới và giữ mapping `(table, legacy key) → UUID`; cần inventory type của legacy key và mọi FK/consumer. Chọn shadow UUID columns hay bảng chuyển tiếp. | Mapping bền vững hỗ trợ rollback/audit; parallel tables cách ly tốt hơn nhưng cần cutover/versioning. Không cast bigint trực tiếp. | Chưa chốt vì live type/relationships chưa probe. |
| Dữ liệu tags cũ được encode thế nào? | Cần sample/inventory có kiểm soát từ backup và xác nhận delimiter, escaping, trim/duplicate semantics. | Chọn parser sai có thể mất tag hoặc tạo tag giả; giữ raw field đến khi mapping được duyệt. | Chưa đủ dữ liệu; không tự chọn delimiter. |
| Nguồn `dream_date` là gì cho từng row cũ? | Cần nguồn đáng tin cậy hoặc quyết định để row unresolved/manual entry. | Dùng `created_at` có thể đổi ngày giấc mơ thành ngày nhập; tự điền làm sai lịch sử. | Chưa đủ dữ liệu; không suy từ `created_at`. |
| Format/timezone của legacy sleep time là gì? | Trước tiên xác minh live columns và values; quyết định timezone, DST, date context, invalid/ambiguous handling. | Parse sai có thể lệch ngày/thời lượng; rows mơ hồ cần giữ raw/unresolved. | Chưa đủ dữ liệu; không suy timezone. |
| Legacy quality ánh xạ ra 0–100 thế nào? | Xác minh live type, range, semantics và distribution; chủ dự án duyệt công thức hoặc giữ unresolved. | Scale tuyến tính hay mapping khác tạo giá trị khác; áp dụng tự động có thể bóp méo lịch sử. | Chưa đủ dữ liệu; không tự nhân 10. |
| Sleep stages và notes được xử lý ra sao? | Không có stage source đã xác minh; xác định nullable/default/unknown semantics. Xác minh live note field và null/empty. | Stage defaults không đồng nghĩa dữ liệu đo. Notes có thể mất khác biệt giữa null/rỗng nếu normalize không có quy tắc. | Chưa đủ dữ liệu; không tạo stage values. |
| Owner/FK/cascade và các security policies live là gì? | Read-only catalog inventory, orphan counts, RLS/policies/grants, triggers/indexes. | Sai owner mapping hoặc bypass RLS có thể gây lộ/chuyển nhầm dữ liệu. | Chưa xác minh live. |
| Chọn shadow columns hay parallel transition tables? | Khuyến nghị đánh giá parallel tables vì cô lập legacy; cần review consumers, atomicity, dual-write và cutover. | Shadow columns ít đổi tên nhưng tăng nguy cơ lẫn old/new writes; parallel tables cần mapping và API versioning. | Chưa chốt. |
| Backup và phục hồi đáp ứng mức nào? | Chọn công cụ, owner, retention, RPO/RTO; restore rehearsal vào môi trường cô lập. | Không có restore evidence thì không có phương án phục hồi đáng tin cậy. | Bắt buộc trước migration; chưa thực hiện. |
| Cutover/rollback như thế nào? | Chốt phiên bản API, feature gate/traffic switch, read/write compatibility, monitoring window và rollback/forward-fix owner. | Sau writes vào target, quay lại bằng cách bỏ cột không an toàn; cần replay/compatibility plan. | Chưa chốt. |

## 4. Điều kiện backup/restore

Trước bất kỳ migration hoặc backfill nào:

1. Xác nhận đúng project và môi trường.
2. Backup schema, rows, constraints/FKs, policies/grants, indexes, sequences/identity, triggers/functions liên quan và mapping cần thiết bằng công cụ được chủ dự án duyệt.
3. Lưu backup ngoài Git với quyền truy cập hạn chế; không đưa PII hoặc credentials vào tài liệu/repository.
4. Restore backup vào project/database cô lập, so row counts theo bảng/owner, constraints, ownership và khả năng đọc dữ liệu.
5. Ghi nhận RPO/RTO, retention, người vận hành và người có quyền quyết định dừng/khôi phục.
6. Không tiếp tục nếu restore rehearsal hoặc kiểm tra tính toàn vẹn thất bại.

Không có backup/restore nào được tạo trong Đợt 8E.1.

## 5. Điều kiện staging và rollback

- Chạy migration/backfill thử trên bản restore hoặc staging có schema/data được xác nhận; không thử trên production để tìm mapping.
- Migration/backfill phải idempotent, có checkpoint, batch plan, mapping audit, unresolved report và ngưỡng sai lệch được phê duyệt.
- Reconcile source/target counts, UUID mapping uniqueness, owner/FK integrity, field comparisons/checksums, timestamps, duration và lỗi parse trước cutover.
- Test API với ít nhất hai user riêng, bao gồm CRUD, ownership, expired/invalid token, RLS/grants và error sanitization.
- Cutover chỉ khi app/API version tương thích và chủ dự án phê duyệt rõ thời điểm.
- Rollback trước cutover phải giữ nguyên legacy source. Sau writes vào target cần forward-fix/replay plan; không xóa target hoặc mapping để giả lập rollback.
- Không drop/rename legacy objects hoặc xóa dữ liệu trong đợt đầu.

## 6. Danh sách chủ dự án cần phê duyệt

1. Xác nhận đúng project/environment và mục tiêu là bảo toàn toàn bộ dữ liệu đang có.
2. Cung cấp quyết định hoặc nguồn evidence cho tags, `dream_date`, timezone/DST, quality, notes và các row không thể ánh xạ; không cần gửi dữ liệu nhạy cảm qua chat.
3. Phê duyệt mô hình UUID mapping và lựa chọn shadow columns hay parallel transition tables.
4. Phê duyệt target handling cho các row thiếu dữ liệu bắt buộc (giữ legacy/unresolved, manual remediation, hay phương án khác); không âm thầm đặt default.
5. Chốt RPO/RTO/retention, backup owner, restore rehearsal và staging environment.
6. Review API/RLS/ownership/cutover/rollback plan và ngưỡng reconciliation.
7. Phê duyệt riêng migration version, project/environment, lịch thực thi và người chịu trách nhiệm. Yêu cầu “kết nối dự án” hoặc “lập kế hoạch” không tự động đồng nghĩa phê duyệt ghi schema/data.

## 7. Phạm vi Đợt 8E.1

Chỉ cập nhật tài liệu. Không đọc/sửa `.env` hoặc `server/.env`; không chạy SQL, migration, backup, restore hoặc write query; không đổi schema, RLS, policy, dữ liệu, Flutter, Express hay API CRUD; không commit/push.
