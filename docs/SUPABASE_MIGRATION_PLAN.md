# Supabase Migration Plan — Dream Diary (Đợt 8E.1)

**Trạng thái:** kế hoạch review; chưa có migration SQL executable và chưa thay đổi Supabase. Project đã được xác minh bằng REST schema probes chỉ đọc (`SELECT ... LIMIT 0`); probes không lấy rows và chỉ xác minh sự hiện diện của cột, không xác minh kiểu dữ liệu, nullability, default, constraint, index, policy hay grants.

**Ưu tiên:** giữ nguyên mọi dữ liệu legacy, duy trì khả năng khôi phục và rollback. Kiến trúc ứng dụng: Flutter → Express REST API → Supabase PostgreSQL/Auth. Flutter không truy cập Supabase trực tiếp cho CRUD nghiệp vụ.

## 1. Hai nguồn hiện trạng cần phân biệt

### 1.1 Project Supabase thực tế đã xác minh

Kết quả được ghi trong `docs/TASK_LOG.md` ở mục “Supabase connection investigation”. Các probes kiểm tra metadata cột bằng query không lấy row:

| Bảng | Cột hiện diện trong project theo probe | Cột đích được probe nhưng chưa hiện diện |
|---|---|---|
| `dreams` | `id`, `user_id`, `title`, `content`, `emotion`, `tags`, `created_at` | `clarity_score`, `is_lucid`, `dream_date` |
| `sleep_records` | `id`, `user_id`, `duration_minutes`, `created_at` | `start_time`, `end_time`, `quality_score`, `deep_sleep_minutes`, `light_sleep_minutes`, `rem_sleep_minutes`, `notes` |

Kết quả này **không xác minh** kiểu dữ liệu hoặc constraint của cột hiện diện; cũng không xác minh các legacy column `sleep_time`, `wake_time`, `quality`, `note`, quan hệ FK, RLS/policies/grants, indexes, triggers, row count hoặc nội dung dữ liệu. Không suy rộng từ schema file trong repository sang project live.

### 1.2 Schema tham chiếu trong repository

Theo `supabase_schema.sql` đã review tĩnh (không phải inventory live):

- `dreams`: `id bigint identity`, owner UUID FK tới `auth.users`, `title/content/emotion/tags` là text, `created_at timestamptz`; chưa có `clarity_score`, `is_lucid`, `dream_date`.
- `sleep_records`: `id bigint identity`, owner UUID FK tới `auth.users`, `sleep_time/wake_time` text, `duration_minutes integer`, `quality integer` 1–10, `note text`, `created_at timestamptz`; chưa có `start_time/end_time` TIMESTAMPTZ và các stage-minute fields.
- SQL tham chiếu khai báo RLS/policies theo `auth.uid() = user_id`, grants, và index owner/created. **Các khai báo này chưa được xác nhận trên project live trong Đợt 8E.1.**

## 2. Hợp đồng đích

Hợp đồng đích lấy từ `docs/DATA_CONTRACT.md` và `docs/API_SPECIFICATION.md`, không phải mô tả hiện trạng live:

- Dream: UUID ID; owner từ JWT; text title/content/emotion; `tags text[]`; clarity 1–5; lucid boolean; `dream_date DATE`; `created_at TIMESTAMPTZ`.
- Sleep: UUID ID; owner từ JWT; `start_time/end_time TIMESTAMPTZ`; `duration_minutes` do Express tính; quality 0–100; các stage minutes không âm; notes; `created_at TIMESTAMPTZ`.
- `id`, `user_id`, `created_at` là server/database-managed. Client không gửi `duration_minutes`.
- GET list trả JSON array trực tiếp; Express lọc owner theo JWT đã xác minh.

Hợp đồng đích không xác định cách diễn dịch dữ liệu legacy còn mơ hồ; không được tạo giá trị thay thế để làm đầy cột đích.

## 3. Bảng mapping legacy → đích

“Hiện diện” và “thiếu” bên dưới là kết quả probe live; kiểu dữ liệu/constraint live chưa xác minh trừ khi ghi khác. Không có mapping nào trong bảng này được phép chạy trước khi được phê duyệt.

| Thành phần legacy | Trạng thái live đã kiểm tra | Trường đích | Phương án bảo toàn đề xuất | Trạng thái quyết định / rủi ro |
|---|---|---|---|---|
| Dream `id` | Cột hiện diện; live type chưa kiểm tra. Repository SQL tham chiếu nói `bigint identity`. | UUID `id` | Không cast. Tạo UUID mới và mapping bền vững từ khóa legacy đã xác minh sang UUID; giữ legacy ID và mapping trong suốt thời gian tương thích/khôi phục. | Cần xác minh type, PK/FK và consumers. Chưa chọn shadow column hay bảng chuyển tiếp. |
| Dream `user_id` | Cột hiện diện; live type/FK chưa kiểm tra. | UUID `user_id` từ Supabase Auth | Giữ raw value; trước backfill xác minh mọi giá trị khớp Auth user và FK/ownership. Không sửa owner tự động. | Chưa xác minh orphan rows, FK, cascade hoặc type live. |
| Dream `title`, `content`, `emotion` | Cột hiện diện; type/nullability/constraints live chưa kiểm tra. | Giữ cùng field | Sao chép nguyên giá trị sau khi xác minh encoding, nullability và giới hạn API/DB. | Cần báo cáo null, length và emotion ngoài enum trước cutover; không tự normalize âm thầm. |
| Dream `tags` | Cột hiện diện; live type và serialized format chưa xác minh. Repository SQL tham chiếu khai báo `text`. | `text[]` | Giữ nguyên raw source. Chỉ parse sau khi xác định delimiter/escaping từ evidence và được duyệt; ghi mapping status/error để row mơ hồ không mất dấu. | **Chưa đủ dữ liệu. Không tự chọn delimiter, không split theo giả định, không thay bằng mảng rỗng.** |
| Dream `clarity_score`, `is_lucid` | Chưa hiện diện theo probe. | integer 1–5; boolean | Không có nguồn legacy được xác minh. Thêm như shadow/transition fields chỉ khi chủ dự án duyệt semantics và default; nếu chưa thì giữ record ở legacy/unresolved, không tự gán dữ liệu. | **Chưa có dữ liệu nguồn; default contract không đồng nghĩa được phép ghi đè quá khứ.** |
| Dream `dream_date` | Chưa hiện diện theo probe. | `DATE` theo contract | Không suy từ `created_at`. Giữ chưa ánh xạ cho đến khi có nguồn ngày đáng tin cậy hoặc quyết định xử lý từng row. | **Chưa đủ dữ liệu. `created_at` không chứng minh ngày đã mơ.** |
| Dream `created_at` | Cột hiện diện; live type/default chưa kiểm tra. | `TIMESTAMPTZ` | Giữ raw/backup; chỉ copy sau khi xác minh kiểu và timezone semantics. | Không khẳng định type live chỉ từ tên cột. |
| Sleep `id` | Cột hiện diện; live type chưa kiểm tra. Repository SQL tham chiếu nói `bigint identity`. | UUID `id` | UUID mới + mapping bền vững; tuyệt đối không cast bigint sang UUID. | Cần xác minh PK/FK và consumers trước khi chọn mapping key. |
| Sleep `user_id` | Cột hiện diện; live type/FK chưa kiểm tra. | UUID từ JWT/Auth | Giữ raw value; xác minh ownership và orphan trước backfill. | Chưa xác minh type, FK, cascade hoặc dữ liệu owner. |
| Sleep `sleep_time`, `wake_time` | Chưa probe được trên live. Chỉ có trong schema tham chiếu dạng text. | `start_time`, `end_time` UTC instants | Trước tiên inventory live schema và format thực tế. Giữ nguyên raw values. Chỉ parse với timezone/DST rule được duyệt; lỗi hoặc mơ hồ giữ ở legacy/unresolved. | **Chưa đủ dữ liệu. Không suy timezone hoặc ngày qua `created_at`.** |
| Sleep `duration_minutes` | Cột hiện diện; live type/meaning/consistency chưa kiểm tra. | Server-calculated integer từ hai timestamp | Không coi giá trị hiện tại là authoritative cho tới khi đối chiếu với timestamps đã được phê duyệt. Giữ giá trị legacy riêng và báo cáo chênh lệch; target duration tính từ start/end ở Express. | Chưa biết nó được tạo bởi công thức nào và có được ghi bởi client hay không. |
| Sleep `quality` | Chưa probe được trên live. Schema tham chiếu nói integer 1–10, chưa xác nhận thực tế. | `quality_score` integer 0–100 | Giữ raw numeric/text value. Không scale hoặc map cho đến khi type, phân phối, semantics và công thức được chủ dự án duyệt. | **Chưa đủ dữ liệu. Không tự nhân 10 hoặc suy diễn giá trị.** |
| Sleep stage minutes | Chưa có trong schema tham chiếu; live chưa được probe riêng ngoài các target columns bị thiếu. | deep/light/REM minutes | Không tạo dữ liệu stages. Có thể để unresolved/unknown ở transition path cho tới khi quyết định rõ target nullable/default và semantics. | **Không có nguồn legacy đã biết; không sinh dữ liệu giả.** |
| Sleep `note` | Chưa probe được trên live. Chỉ có trong schema tham chiếu dạng text. | `notes` | Nếu xác minh tồn tại, copy raw text sau khi thống nhất null/empty semantics; giữ source nguyên trạng. | Live existence và type chưa xác minh. |
| Sleep `created_at` | Cột hiện diện; live type/default chưa kiểm tra. | `TIMESTAMPTZ` | Giữ raw/backup, xác minh type/semantics trước khi copy. | Không dùng thay `start_time`/`end_time`. |

## 4. Chiến lược additive đề xuất

Đây là chiến lược để review, chưa phải lệnh triển khai:

1. **Đóng băng hiện trạng và inventory chỉ đọc:** xác minh project/environment; lấy schema catalog cho columns/types/nullability/default/PK/FK/check/index/RLS/policies/grants/triggers và row counts. Không xuất row content vào repo.
2. **Backup đầy đủ và restore rehearsal:** sao lưu schema, data, policies/grants, indexes, sequences, triggers/functions và identity dependencies theo công cụ được duyệt. Restore vào môi trường cô lập, chứng minh so sánh counts/integrity. Ghi rõ backup owner, retention, RPO/RTO.
3. **Chọn mô hình chuyển tiếp:** ưu tiên cân nhắc bảng chuyển tiếp song song để giữ nguyên legacy tables; thay thế ít rủi ro hơn là shadow columns nếu constraints/consumers chứng minh tương thích. Chưa chốt tên bảng/cột, loại ID legacy hoặc DDL.
4. **UUID mapping riêng:** cấp UUID mới cho từng row; lưu ánh xạ `(legacy_table, legacy_id_verified_type/value) → target_uuid` bền vững. Không cast hoặc tái sử dụng bigint thành UUID. Không xóa mapping trước khi chủ dự án cho phép kết thúc thời gian tương thích.
5. **Giữ raw và đánh dấu unresolved:** mọi trường chưa có mapping an toàn (tags, dream date, sleep timestamps/quality/stages) phải giữ nguyên source, có trạng thái unresolved và không bị biến thành default “có vẻ hợp lệ”. Không đưa row chưa đủ trường bắt buộc vào API mới.
6. **Backfill idempotent theo batch sau khi được duyệt:** có checkpoint, row-level error report, retry không nhân đôi target row; không update/drop legacy record. Tách migration schema khỏi backfill dữ liệu nếu cần.
7. **Reconcile trước cutover:** so tổng row, row mapped/unresolved/quarantined, UUID uniqueness, owner/FK integrity, raw-to-target checksums/field comparisons, timestamp parse, duration recompute và số lượng lỗi theo owner. Sai lệch phải nằm trong ngưỡng được duyệt; không tự loại bỏ rows.
8. **Staging và cutover có cổng:** chạy test bằng tài khoản/fixtures riêng trên bản restore; cross-account isolation, API CRUD, RLS/grants, rollback và replay. Chuyển API traffic chỉ sau khi phê duyệt. Giữ legacy tables và đường phục hồi trong đợt đầu.
9. **Không cleanup trong đợt đầu:** không drop/rename legacy tables/columns, không xóa mapping/quarantine, không thu hẹp grants hoặc dữ liệu. Cleanup là migration riêng sau thời gian quan sát và phê duyệt độc lập.

### Shadow columns hay bảng chuyển tiếp?

- **Bảng chuyển tiếp song song (đang được ưu tiên để đánh giá):** cách ly schema/API mới, giữ legacy table nguyên vẹn và rollback cutover dễ hơn; đổi lại cần mapping, đồng bộ owner/index/policies, và quyết định xử lý dữ liệu chưa ánh xạ.
- **Shadow columns:** ít thay đổi table/API names nhưng rủi ro nhầm old/new columns, constraints và client cũ ghi song song; chỉ xem xét sau inventory consumers/transactions và có quy tắc dual-write rõ.
- Chưa chọn phương án cuối. Không có executable SQL trong tài liệu này.

## 5. Đối chiếu và integrity gates

Trước backfill và trước cutover phải có báo cáo (không chỉ log “success”):

- Số row source theo bảng và owner; số row target/mapped/unresolved; số row bị lỗi và lý do. Source count không đổi.
- Một mapping target UUID duy nhất cho mỗi legacy key; không có target UUID trùng hoặc map nhầm owner.
- FK/orphan owner, uniqueness, not-null/check/default, RLS/policies/grants và index phù hợp đã kiểm tra trên staging.
- Raw legacy values giữ được từ backup/legacy table; so sánh field-by-field hoặc checksum theo chính sách PII an toàn.
- Không có conversion ngầm cho tags/date/timezone/quality/stages. Report riêng tất cả giá trị chưa thể diễn giải.
- Với sleep rows đã được ánh xạ hợp lệ, đối chiếu duration target với phép tính Express từ timestamp được duyệt; không ghi đè duration cũ trước khi có kết quả reconcile.
- Thử API bằng hai user riêng: không đọc/sửa/xóa chéo owner; kiểm tra token thiếu/hết hạn, retry và các lỗi sanitized.

## 6. Backup, restore và rollback

- Không bắt đầu thay đổi trước backup có thể khôi phục. Backup phải có schema, policies/grants, indexes, FK/constraints, sequences/identity, triggers/functions và dữ liệu legacy cần bảo toàn; lưu ngoài Git với quyền hạn chế.
- Restore rehearsal vào project riêng/staging, xác nhận số lượng, quan hệ, quyền và khả năng chạy lại các bước. Một backup job hoàn tất không thay thế restore rehearsal.
- Chốt RPO, RTO, retention, người sở hữu backup và người có quyền dừng/khôi phục trước khi migration.
- Trước cutover: rollback về API/schema legacy mà không xóa source. Sau khi target bắt đầu nhận writes: cần forward-fix hoặc replay plan có kiểm thử; không rollback bằng cách bỏ target columns/tables.
- Đợt đầu không drop/rename và không xóa rows/mapping. Giữ đường đọc/khôi phục legacy cho tới khi chủ dự án phê duyệt cleanup riêng.

## 7. RLS, ownership và quyền truy cập

- Trạng thái RLS/policies/grants thực tế **chưa được xác minh** bởi schema probes Đợt 8E.1. SQL trong repository chỉ là tham chiếu.
- Trước cutover phải inventory live policy/grants. API server dùng privileged Supabase client nên mỗi query phải lọc theo `req.user.id` từ JWT đã xác minh; test/static review mọi list, insert, update, delete.
- Nếu bật direct authenticated CRUD policy, xác minh `auth.uid() = user_id` cho SELECT/INSERT/UPDATE/DELETE bằng hai user A/B trên staging; quyết định quyền direct client phù hợp với kiến trúc Express-only.
- Không đưa service-role key vào Flutter. Không sửa policy/grants trong kế hoạch này.

## 8. Điều kiện cho phép tạo và áp dụng migration

Chỉ chuyển thành migration executable sau khi tất cả mục phù hợp được review/phê duyệt:

1. Xác nhận rõ project/environment đang nhắm tới và đây không phải nhầm project.
2. Hoàn tất read-only catalog/data inventory, gồm legacy columns thực tế, types, constraints, policies/grants và consumers.
3. Quyết định có dữ liệu cần giữ và thời gian giữ legacy/mapping; trong Đợt 8E.1 mặc định là bảo toàn toàn bộ, không cleanup.
4. Phê duyệt từng mapping mơ hồ: tags serialization; nguồn `dream_date`; timezone/DST của thời gian ngủ; quality; sleep stages; notes null/empty; owner/orphan handling.
5. Chốt shadow columns hay bảng chuyển tiếp, UUID mapping retention, API cutover/versioning và write compatibility.
6. Backup hoàn tất và restore rehearsal đạt; RPO/RTO/retention và rollback/forward-fix owner được xác nhận.
7. Staging run, idempotency, batch/lock estimates, reconciliation thresholds và ownership/RLS tests đạt.
8. Chủ dự án phê duyệt rõ migration version, môi trường, thời điểm thực thi và người chịu trách nhiệm. Không suy ra phê duyệt thực thi chỉ từ yêu cầu lập kế hoạch.

## 9. Trạng thái sau Đợt 8E.1

- Kế hoạch cập nhật phân biệt kết quả probe live với SQL tham chiếu trong repo.
- Không đọc `.env`/`server/.env`, không chạy SQL, không lấy row data, không tạo migration executable, không thay schema/policy/dữ liệu, không sửa Flutter/Express/API và không commit/push.
- Dream/Sleep CRUD chưa được bật trong Flutter; các API routes phụ thuộc schema contract mới.
- Các quyết định và tác động được theo dõi riêng tại `docs/8E_MIGRATION_DECISIONS.md`.
