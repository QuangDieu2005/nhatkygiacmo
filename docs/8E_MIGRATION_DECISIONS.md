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
| Initial REST probes chỉ kiểm tra column presence; sau đó chủ dự án cung cấp catalog/security/count inventory đầy đủ hơn. | Đã thực hiện theo các snapshot riêng | Không lấy row content; counts là snapshot và cần recheck trước migration. |

## 2. Hiện trạng live đã xác minh và giới hạn

Kết quả kiểm kê đầy đủ được chủ dự án cung cấp trong yêu cầu Đợt 8E.3. Kết quả này được xem là snapshot live tại thời điểm kiểm tra; agent không chạy lại query trong Đợt 8E.3.

| Bảng | Schema live được xác minh | Security/objects/count |
|---|---|---|
| `dreams` | `id bigint identity PK`; `user_id UUID NOT NULL` FK tới `auth.users(id) ON DELETE CASCADE`; `title/content/emotion text NOT NULL`; `tags text NOT NULL DEFAULT ''`; `created_at timestamptz NOT NULL DEFAULT now()`. Thiếu clarity/lucid/date. | RLS enabled, not forced; đủ SELECT/INSERT/UPDATE/DELETE cho `authenticated`, `auth.uid() = user_id`; PK index và `(user_id, created_at DESC)`; không tìm thấy custom trigger. Count = 0 tại thời điểm kiểm tra. |
| `sleep_records` | `id bigint identity PK`; `user_id UUID NOT NULL` FK tới `auth.users(id) ON DELETE CASCADE`; `sleep_time/wake_time text NOT NULL`; `duration_minutes integer NOT NULL CHECK >= 0`; `quality integer NOT NULL CHECK 1–10`; `note text NOT NULL DEFAULT ''`; `created_at timestamptz NOT NULL DEFAULT now()`. Thiếu start/end, quality_score, stage fields, notes. | RLS enabled, not forced; đủ SELECT/INSERT/UPDATE/DELETE cho `authenticated`, `auth.uid() = user_id`; PK index và `(user_id, created_at DESC)`; không tìm thấy custom trigger. Count = 0 tại thời điểm kiểm tra. |

Grants đã được kiểm tra theo inventory nhưng grant matrix chi tiết không có trong thông tin được cung cấp ở đây. Không tự suy diễn role grants hoặc thay đổi quyền. Không tìm thấy PostgreSQL direct function dependencies; điều này không loại trừ references trong PL/pgSQL hoặc SQL động. Counts 0/0 là snapshot, phải recheck trước migration.

## 3. Quyết định còn thiếu và tác động

| Câu hỏi cần quyết định | Lựa chọn / dữ liệu cần có | Tác động nếu chọn | Trạng thái |
|---|---|---|---|
| Project/environment nào sẽ là đích? | Xác nhận rõ dev/staging/production và project ref qua kênh an toàn; không ghi secret vào repo/docs. | Sai project có thể làm gián đoạn dữ liệu thật; quyết định backup/approval khác nhau theo môi trường. | Chờ xác nhận trước migration. |
| Primary strategy cho ID là gì? | Live PK đã xác minh là `bigint identity`; target/API cần UUID. Ưu tiên UUID mới cùng mapping `(table, legacy bigint id) → UUID`; inventory consumers/FKs vẫn cần. | Mapping bền vững hỗ trợ audit/rollback. Không cast bigint trực tiếp. | Legacy type đã rõ; retention/schema cụ thể của mapping và consumers còn chờ. |
| Dữ liệu tags cũ được encode thế nào? | Cần sample/inventory có kiểm soát từ backup và xác nhận delimiter, escaping, trim/duplicate semantics. | Chọn parser sai có thể mất tag hoặc tạo tag giả; giữ raw field đến khi mapping được duyệt. | Chưa đủ dữ liệu; không tự chọn delimiter. |
| Nguồn `dream_date` là gì cho từng row cũ? | Cần nguồn đáng tin cậy hoặc quyết định để row unresolved/manual entry. | Dùng `created_at` có thể đổi ngày giấc mơ thành ngày nhập; tự điền làm sai lịch sử. | Chưa đủ dữ liệu; không suy từ `created_at`. |
| Format/timezone của legacy sleep time là gì? | Live columns đã xác minh là `sleep_time/wake_time text NOT NULL`; cần xác minh formats, date context, timezone, DST, invalid/ambiguous handling. | Parse sai có thể lệch ngày/thời lượng; giữ raw/unresolved. | Tồn tại/type đã rõ; nội dung và timezone semantics còn chờ. |
| Legacy quality ánh xạ ra 0–100 thế nào? | Live `quality integer NOT NULL CHECK 1–10` đã xác minh; cần semantics/distribution và quyết định mapping target. | Scale tuyến tính hay mapping khác tạo giá trị khác; áp dụng tự động có thể bóp méo lịch sử. | Type/range đã rõ; conversion chưa được duyệt, không tự nhân 10. |
| Sleep stages và notes được xử lý ra sao? | Stage columns không có trong live table; `note text NOT NULL DEFAULT ''` đã xác minh. Chốt target unknown/default và note handling. | Stage defaults không đồng nghĩa dữ liệu đo. Notes cần giữ raw và semantics target rõ. | Stage source chưa có; note source/type đã rõ. |
| Owner/FK/cascade và policies live là gì? | Inventory đã xác nhận UUID FK cascade, RLS/policies owner-scope, indexes và không FORCE RLS. Orphan counts/consumer behavior cần kiểm tra lại trước cutover. | Duy trì owner association, cascade và RLS khi thiết kế target; mọi thay đổi policy/grant cần review riêng. | Phần schema/policy được xác minh; orphan/consumer status còn chờ. |
| Chọn shadow columns hay parallel transition tables? | So sánh ở mục 9; khuyến nghị bảng contract mới song song để cách ly legacy. | Bảng mới giữ nguyên legacy đơn giản hơn nhưng buộc đổi Express route target và có rollout riêng. | Khuyến nghị B để review; chưa được phê duyệt triển khai. |
| Backup và phục hồi đáp ứng mức nào? | Chọn công cụ, owner, retention, RPO/RTO; restore rehearsal vào môi trường cô lập. | Không có restore evidence thì không có phương án phục hồi đáng tin cậy. | Bắt buộc trước migration; chưa thực hiện. |
| Cutover/rollback như thế nào? | Chốt phiên bản API, feature gate/traffic switch, read/write compatibility, monitoring window và rollback/forward-fix owner. | Sau writes vào target, quay lại bằng cách bỏ cột không an toàn; cần replay/compatibility plan. | Chưa chốt. |
| Account-data deletion khi có target tables? | Backend hiện xóa hai legacy tables bằng hai request riêng, không atomic. Xác định API behavior/recovery và bảo đảm target rows cũng được xử lý trước expose. | Nếu không cập nhật, account deletion sẽ bỏ sót target rows; thao tác từng bảng có thể xóa một phần. | Blocker rollout; chưa thiết kế/sửa trong 8E.3. |

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

## 8. Cập nhật Đợt 8E.2 — inventory đang chờ chạy thủ công

- Đã tạo `docs/8E_READ_ONLY_INVENTORY.sql` với các nhóm SELECT để chủ dự án review metadata columns, constraints, indexes, triggers/function identities, RLS/policies, grants, legacy columns và aggregate counts.
- Đã tạo `docs/8E2_INVENTORY_GUIDE.md` hướng dẫn chạy từng statement trong Supabase SQL Editor, hiểu giới hạn catalog/RLS và che thông tin trước khi chia sẻ.
- Bộ SQL chưa được chạy bởi agent và không chứng minh inventory live đã hoàn tất. Kết quả 8E.1 vẫn chỉ là column-presence probe.
- Không thay đổi quyết định mapping; tags, dream date, legacy sleep timezone, quality, stages, ID strategy details, backup/restore, staging và rollback vẫn cần evidence/phê duyệt.

## 9. Cập nhật Đợt 8E.3 — thiết kế theo inventory đã cung cấp

### Phương án và khuyến nghị

| Phương án | Ưu điểm | Rủi ro / tương thích | Rollback |
|---|---|---|---|
| A. Thêm shadow fields trên bảng hiện tại | Giữ nguyên bảng/tên route; có thể giữ legacy values. | `id` bigint và `tags text` xung đột với DTO cần UUID/array; legacy NOT NULL/check có thể chặn insert mới; cần projection/view, dual writes và test RLS. Routes hiện tại chưa dùng shadow fields. | Phức tạp sau dual-write; cần compatibility layer và source-of-truth rõ. |
| B. Tạo bảng contract mới, giữ bảng cũ | Legacy tables không bị mutate; schema UUID/array/date/time mới tách biệt; rollback trước cutover đơn giản hơn. | Cần đổi Express query target/API rollout; mapping table và security/index objects mới; sau writes không được bỏ target. | Giữ cả hai bộ bảng; sau cutover dùng forward-fix hoặc API version còn đọc target, không xóa target rows. |

**Khuyến nghị review: B**, với target table names tạm thời như `dreams_v2`/`sleep_records_v2` (chưa chốt). Nếu counts recheck vẫn 0 thì không backfill. Nếu counts đổi, dừng cho đến khi mapping từng nhóm được duyệt. Đây chưa phải approval cho DDL, backfill hoặc cutover.

### Quyết định mapping chưa có

- Tags: text source vẫn cần xác định delimiter/escaping; không split tự đoán.
- Dream date: không có source; không lấy `created_at` làm ngày mơ.
- Sleep timestamps: format/timezone/DST của hai text fields chưa rõ; giữ raw và không parse tự suy.
- Quality: giữ raw integer 1–10; chưa có conversion được duyệt sang 0–100.
- Clarity/lucid và sleep stages: không có source legacy; không điền default như dữ liệu lịch sử.
- UUID mapping: live ID type đã xác minh là bigint identity; target UUID phải mới và liên kết bằng bảng mapping, không cast.
- Target grants, target table naming, consumer/write freeze, backup/RPO/RTO, staging thresholds, cutover/rollback owner vẫn cần chốt.
- Account-data deletion endpoint hiện chỉ đụng legacy tables và không atomic; thiết kế việc xử lý target tables là blocker trước expose CRUD.

Các điều kiện backup/restore, staging, stop conditions và phê duyệt thực thi được cụ thể hóa trong `docs/SUPABASE_MIGRATION_PLAN.md`. Chưa có SQL executable hoặc thao tác Supabase trong Đợt 8E.3.
