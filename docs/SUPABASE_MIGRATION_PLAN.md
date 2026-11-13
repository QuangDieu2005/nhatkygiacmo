# Supabase Migration Plan — Dream Diary (Đợt 8E.4)

**Trạng thái:** có SQL draft `supabase/migrations/DRAFT_ONLY_create_api_v2_tables.sql` để review; không phải migration được phê duyệt và chưa chạy. Inventory live được chủ dự án cung cấp sau khi chạy bộ inventory thủ công. Không kết nối hoặc chạy lại SQL trong Đợt 8E.4.

**Ưu tiên:** bảo toàn dữ liệu legacy, duy trì đường phục hồi. Không drop, truncate, rename hoặc ghi đè bảng/cột cũ trong migration đầu tiên.

## 1. Kiến trúc và contract đích

Kiến trúc nghiệp vụ: **Flutter → Express REST API → Supabase PostgreSQL/Auth**. Flutter không CRUD trực tiếp với Supabase. API routes hiện tại lọc owner bằng `req.user.id`, trả list JSON array và parse/validate theo contract mới.

Contract target theo `docs/DATA_CONTRACT.md`, `docs/API_SPECIFICATION.md`, `server/src/routes/dreams.js`, `server/src/routes/sleepRecords.js`, `server/src/validation.js`:

- Dream: UUID `id`; UUID `user_id` lấy từ JWT đã xác minh; `title`, `content`, `emotion` text; `tags` text array; `clarity_score` integer 1–5; `is_lucid` boolean; `dream_date` DATE; `created_at` timestamp.
- Sleep: UUID `id`; UUID `user_id`; `start_time`/`end_time` timestamp có timezone; `duration_minutes` do Express tính; `quality_score` integer 0–100; ba stage-minute integer không âm; `notes`; `created_at`.
- API hiện dùng `dreams` và `sleep_records`, UUID path/body response fields; request không nhận `id`, `user_id`, `created_at`, `duration_minutes` hoặc trạng thái tracking.
- Express routes truy vấn các trường contract trực tiếp trên `dreams`/`sleep_records`. Do đó schema contract mới phải được cung cấp ở đúng API boundary hoặc routes được đổi trong một rollout riêng trước khi mở CRUD.
- `DELETE /api/account/data` hiện xóa theo hai request liên tiếp trên legacy `dreams` rồi `sleep_records`, không atomic. Khi target tables được dùng, endpoint này sẽ không xóa target data nếu chưa cập nhật backend; cần thiết kế hành vi all-or-nothing/recovery và test trước expose. Đây là blocker cutover, không sửa trong Đợt 8E.3.

## 2. Schema live đã kiểm kê

> Nguồn: inventory results do chủ dự án cung cấp trong yêu cầu Đợt 8E.3. Đây là snapshot tại thời điểm kiểm tra, không đảm bảo trạng thái không đổi tới lúc migration.

### `public.dreams`

- `id bigint identity`, primary key.
- `user_id UUID NOT NULL`, FK `auth.users(id) ON DELETE CASCADE`.
- `title`, `content`, `emotion`: `text NOT NULL`.
- `tags`: `text NOT NULL DEFAULT ''`.
- `created_at`: `timestamptz NOT NULL DEFAULT now()`.
- Không có `clarity_score`, `is_lucid`, `dream_date`.
- RLS enabled, not forced. SELECT/INSERT/UPDATE/DELETE policies cho role `authenticated`; owner rule `auth.uid() = user_id`.
- PK index và index `(user_id, created_at DESC)`. Không có custom trigger được tìm thấy.

### `public.sleep_records`

- `id bigint identity`, primary key.
- `user_id UUID NOT NULL`, FK `auth.users(id) ON DELETE CASCADE`.
- `sleep_time`, `wake_time`: `text NOT NULL`.
- `duration_minutes`: `integer NOT NULL CHECK (duration_minutes >= 0)`.
- `quality`: `integer NOT NULL CHECK (quality BETWEEN 1 AND 10)`.
- `note`: `text NOT NULL DEFAULT ''`.
- `created_at`: `timestamptz NOT NULL DEFAULT now()`.
- Không có `start_time`, `end_time`, `quality_score`, `deep_sleep_minutes`, `light_sleep_minutes`, `rem_sleep_minutes`, `notes`.
- RLS enabled, not forced. SELECT/INSERT/UPDATE/DELETE policies cho role `authenticated`; owner rule `auth.uid() = user_id`.
- PK index và index `(user_id, created_at DESC)`. Không có custom trigger được tìm thấy.

Inventory không tìm thấy function dependency trực tiếp được PostgreSQL ghi nhận trên hai bảng. Điều đó **không chứng minh** không có PL/pgSQL hoặc SQL động tham chiếu tới bảng. Grants đã được kiểm tra; không có grant matrix chi tiết trong yêu cầu này, nên không suy ra hoặc đề xuất thay đổi grants hiện hữu. Cần giữ nguyên grants legacy.

`COUNT(*)` snapshot tại thời điểm kiểm kê: `dreams = 0`, `sleep_records = 0`. Đây không phải bảo đảm số lượng vẫn là 0 khi thực thi. Đếm lại ngay trước mỗi pha có ghi; nếu khác 0, dừng để áp dụng nhánh bảo toàn/backfill đã được duyệt.

## 3. Schema tham chiếu trong repository

`supabase_schema.sql` là schema tham chiếu, không dùng làm bằng chứng thay thế inventory live. Theo file này, legacy schema có bigint identity IDs, Dream tags dạng text, và Sleep fields `sleep_time`/`wake_time` text, `quality` 1–10, `note`; RLS/policies/grants/indexes được khai báo trong SQL. Inventory live được cung cấp hiện đã xác nhận các thuộc tính chính nêu tại mục 2. Không giả định objects khác ngoài kết quả inventory.

## 4. Bảng mapping legacy → target

| Legacy live field | Target/API field | Mapping proposal | Trạng thái / rủi ro |
|---|---|---|---|
| Dream `id bigint identity PK` | `id UUID` | Không cast. Cấp UUID mới trong bảng target; giữ mapping ổn định `(legacy table, legacy bigint id) → target UUID` nếu có backfill hoặc cần truy xuất lịch sử. | Kiểu legacy đã xác minh. Với count hiện tại 0, mapping có thể rỗng nếu recheck vẫn 0; vẫn giữ cơ chế mapping nếu có legacy row. |
| Sleep `id bigint identity PK` | `id UUID` | Cùng nguyên tắc UUID mới + mapping; không đổi PK legacy. | Như trên. |
| `user_id UUID NOT NULL` + FK cascade | `user_id UUID` | Copy nguyên UUID sau khi reconciliation; target giữ FK tới `auth.users(id) ON DELETE CASCADE`. Không thay đổi owner hoặc cascade semantics. | FK/type/cascade đã xác minh. Đếm orphan vẫn phải kiểm tra trước backfill/cutover. |
| Dream `title/content/emotion text NOT NULL` | Cùng tên, text bắt buộc | Copy nguyên giá trị nếu backfill được duyệt; báo counts cho null/invalid emotion/over-limit thay vì normalize âm thầm. | Types/nullability đã xác minh; contract limits/enum cần reconcile. |
| Dream `tags text NOT NULL DEFAULT ''` | `tags text[]` | Giữ cột/source nguyên trạng. Chỉ parse sau khi xác định delimiter, escaping, whitespace/duplicate rules từ evidence và được duyệt. Không thay raw bằng `{}` hoặc split tùy ý. | **Chưa có delimiter/evidence.** Nếu rows xuất hiện trước cutover, unresolved tags là stop condition cho việc đưa row vào API target. |
| Không có legacy clarity/lucid fields | `clarity_score` integer 1–5; `is_lucid` boolean | Không backfill tự động. Record cũ chưa có giá trị nguồn; nếu contract target yêu cầu NOT NULL/default thì quyết định rõ liệu giữ record legacy/unresolved hay nhập bổ sung có nguồn tin cậy. | **Chưa có nguồn. Không gán default lịch sử như thể đó là dữ liệu thật.** |
| Không có legacy `dream_date` | `dream_date DATE` | Không suy từ `created_at`. Chỉ backfill nếu có nguồn ngày đáng tin cậy hoặc chủ dự án duyệt quy trình remediation riêng. | **Chưa có nguồn.** Row chưa có ngày không thể được phục vụ như DreamDTO hiện tại. |
| Dream `created_at timestamptz NOT NULL DEFAULT now()` | `created_at` | Giữ giá trị gốc khi copy; không dùng nó làm ngày mơ. | Kiểu/default đã xác minh. |
| Sleep `sleep_time/wake_time text NOT NULL` | `start_time/end_time` UTC instants | Giữ raw fields. Xác định format, ngày đi kèm, timezone và DST trước parse. Parse failure/ambiguity giữ legacy/unresolved; không sửa source. | **Chưa có sample/semantics được duyệt.** |
| Sleep `duration_minutes integer NOT NULL CHECK >= 0` | `duration_minutes` do Express tính | Giữ giá trị legacy để đối chiếu. Target duration tính từ timestamps hợp lệ; không tin/ghi đè duration legacy trước reconciliation. | Type/check đã xác minh; nguồn/công thức lịch sử chưa xác minh. |
| Sleep `quality integer NOT NULL CHECK 1–10` | `quality_score integer 0–100` | Giữ raw score. Không scale/round/map nếu chưa duyệt semantics/công thức. | **Mapping chưa chốt.** |
| Không có legacy stage columns | `deep/light/rem_sleep_minutes` | Không tạo giá trị cho rows legacy. Phân biệt unknown/missing với số 0 thực; target nullability/default cần decision nếu backfill được yêu cầu. | **Không có nguồn.** Contract API hiện mặc định 0 cho request thiếu, nhưng không dùng default đó để tuyên bố stage lịch sử bằng 0. |
| Sleep `note text NOT NULL DEFAULT ''` | `notes` | Copy nguyên raw text nếu thực hiện backfill; giữ khác biệt null/empty theo schema live (live cột hiện NOT NULL). | Type/default đã xác minh; cần xác nhận giới hạn/semantics API. |
| Sleep `created_at timestamptz NOT NULL DEFAULT now()` | `created_at` | Giữ giá trị gốc; không suy sleep start/end từ cột này. | Đã xác minh. |

Nếu hai bảng vẫn rỗng tại thời điểm migration, không cần backfill rows legacy; bỏ qua mapping giá trị cũ nhưng vẫn giữ nguyên bảng legacy và lưu mapping table rỗng/khả năng mapping nếu policy dự án yêu cầu. Nếu bất kỳ bảng nào có rows mới, không chuyển tự động cho đến khi mapping mơ hồ được duyệt. Không tách unknown, NULL, default và observed value thành cùng một giá trị.

## 5. So sánh hai phương án additive

| Tiêu chí | A. Bổ sung cột/shadow fields trên bảng hiện tại | B. Tạo bảng contract mới, giữ nguyên bảng legacy |
|---|---|---|
| Bảo toàn legacy | Giữ nguyên các cột hiện tại nhưng writes mới và cột cũ cùng tồn tại; cần bảo đảm constraints legacy không chặn insert mới. | Legacy tables không bị sửa; source history giữ nguyên trực tiếp. Target có schema riêng. |
| UUID API ID | `id` hiện là bigint PK; thêm UUID shadow field không làm API hiện tại dùng `id UUID`. Cần view/API projection hoặc sửa routes. | Target có UUID primary key ngay; API routes vẫn cần đổi target table name hoặc qua view. |
| Tags | `tags text` không thể đồng thời là `text[]`; cần shadow array field và API projection. | Target `tags text[]`; raw legacy tags ở nguyên bảng cũ. |
| Code compatibility | Không tương thích trực tiếp với routes hiện tại do UUID `id`, tags array và missing fields; cần compatibility view/projection. View writes/RLS cần test kỹ. | Không tương thích trực tiếp vì routes đang trỏ `dreams`/`sleep_records`; cần đổi cấu hình/routes trong rollout riêng sang target tables. |
| Độ phức tạp | Cao: dual columns, old NOT NULL/check constraints, views, writes cũ/mới đồng thời, backfill trong cùng table. | Trung bình: tạo hai tables, mapping, policies/indexes mới và cutover backend; boundaries rõ hơn. |
| Rủi ro dữ liệu | Có thể tạo state lệch giữa legacy và shadow columns; rollback khó nếu dual-write thiếu. | Legacy records không bị chuyển đổi hoặc mutate; target mới tách biệt. Nếu target writes đã bắt đầu, API rollback phải giữ đường đọc target. |
| Rollback | Khó phân định source of truth sau dual-write; cần đồng bộ hai chiều hoặc compatibility layer. | Trước cutover quay lại legacy dễ; sau target writes không được bỏ target, cần giữ API compatibility/forward-fix và dữ liệu target. |

### Khuyến nghị

**Chọn B — bảng contract mới song song, có điều kiện.** Tên minh họa có thể là `dreams_v2`/`sleep_records_v2` nhưng chưa chốt. Phương án này tách hoàn toàn schema/API mới khỏi PK bigint, `tags text`, và Sleep fields cũ; phù hợp nhất với ưu tiên không chạm/xóa legacy. Hai bảng legacy tiếp tục tồn tại không đổi để đối chiếu và phục hồi.

Điều kiện: inventory row count phải được chạy lại ngay trước migration. Snapshot hiện tại 0/0 không bảo đảm rows vẫn rỗng. Nếu vẫn 0, tạo target tables không backfill. Nếu count khác 0, dừng migration/backfill cho tới khi mapping từng loại dữ liệu được quyết định và rehearsal đạt.

Phương án B vẫn cần thay đổi backend/API source ở một đợt riêng để routes dùng target tables hoặc một compatibility layer đã được test. Không bật các CRUD routes hiện tại trực tiếp với target/legacy schema cho đến khi bảng và route contract khớp. Flutter vẫn dùng mock/local cho tới khi rollout được duyệt.

## 6. Target schema/security design cần review

Đây là thuộc tính thiết kế, không phải DDL:

- Target record ID là UUID primary key do database/server sinh; mapping table giữ legacy table + legacy bigint ID + target UUID, có uniqueness ở cả legacy key và target UUID.
- Owner `user_id UUID NOT NULL` FK `auth.users(id) ON DELETE CASCADE`, đúng contract và legacy semantics.
- Target Dream columns đáp ứng API contract, bao gồm `tags text[]`, `dream_date DATE`, clarity/lucid. Không thêm backfill values cho rows cũ khi không có nguồn.
- Target Sleep columns đáp ứng API contract; duration do Express tính và không nhận từ client. Chốt nullability/default để phân biệt chưa biết với số 0 thực.
- Giữ RLS enabled, không FORCE, và owner policies `auth.uid() = user_id` cho target tables làm baseline đề xuất; verify lại trên staging. Không sửa policies/grants của legacy tables.
- Grant matrix của target tables phải được review theo Express/service-role architecture. Không tự cấp/revoke/đổi grants hiện hữu; mọi thay đổi quyền cần approval riêng. Server dùng privileged client vẫn phải filter mọi query theo JWT owner.
- Tạo target indexes tương đương nhu cầu truy vấn `(user_id, created_at DESC)` và PK; xem xét indexes cho date/time filters sau khi query plan được kiểm tra staging. Không tạo custom trigger/function nếu không có yêu cầu; không khẳng định vắng mặt ngoài kết quả inventory.
- Account-data deletion phải được thiết kế lại trong rollout backend trước khi target data được dùng: hiện endpoint chỉ xóa legacy tables bằng hai request không atomic. Giữ cascade `auth.users` như một safety behavior đã xác minh, nhưng không dựa vào cascade để thay thế hành vi API deletion/retention đã định nghĩa.

## 7. Vận hành theo pha và phân loại thao tác

### Pha 0 — Read-only preflight (chưa ghi)

- Xác nhận đúng project/environment, thời điểm và quyền truy cập; inventory live đầy đủ đã được cung cấp nhưng phải kiểm tra drift trước khi chạy.
- Chạy lại aggregate counts; kiểm tra types/constraints/policies/grants/indexes và table writers/consumers.
- Read-only aggregate checks: số records theo bảng/owner (chỉ counts), orphan owner counts, target duplicate/mapping conflicts nếu đã có staging target, missing/invalid values theo từng field, tags parseability counts, timestamp parse/ambiguity counts, quality range counts, duration mismatch counts. Không export PII.
- **Stop:** nếu counts khác snapshot 0/0 thì không backfill/cutover; yêu cầu mapping approval. Stop nếu inventory drift, unknown writer, permission error, orphan, duplicate mapping, invalid data hoặc kết quả không đầy đủ.

#### Read-only pre/post query checklist (query recipes, chưa phải SQL executable)

| Thời điểm | Aggregate query cần review | Điều kiện đạt / dừng |
|---|---|---|
| Trước DDL | `COUNT(*)` riêng trên từng legacy table; orphan count bằng LEFT JOIN owner tới `auth.users`; nếu cần phân bố theo owner thì chỉ trả bucket/count tổng hợp, không xuất UUID; kiểm tra catalog columns/constraints/policies/grants/indexes. | Snapshot hiện tại 0/0 là baseline tham khảo; nếu count thay đổi, dừng trước backfill và yêu cầu mapping review. Orphan phải bằng 0. |
| Trước backfill | Tổng source rows; số rows đủ điều kiện/unresolved theo từng loại field; invalid format/range counts; mapping conflicts/duplicate counts. Không trả row values. | Không có mapping duplicate; mọi unresolved row phải được giữ ở legacy và không chuyển vào target contract API. |
| Sau backfill staging | Source counts unchanged; target counts bằng số rows đã được duyệt và đủ dữ liệu; mapping coverage/uniqueness; target owner-orphan count; duration recompute mismatch count. | Mọi chênh lệch phải giải thích/được duyệt; nếu không thì rollback staging và dừng. Không xóa source để làm counts khớp. |
| Trước/sau cutover | Target table/field/security metadata; aggregate API success/error counts; owner-isolation tests; account-data deletion reconciliation trên fixture riêng. | Schema, API, RLS/grants và deletion path phải tương thích; cross-user hoặc deletion mismatch là stop condition. |

Queries này phải được review và viết riêng cho schema/version đã xác minh tại thời điểm rehearsal. Không chạy `EXPLAIN ANALYZE` như dry-run vì nó thực thi query. DDL dry-run chỉ thực hiện trên restored staging, không trên production.

### Pha 1 — Backup và restore rehearsal (không sửa production)

- Chủ dự án chọn công cụ backup bao gồm schema/data, RLS/policies/grants, indexes, FK/constraints, sequences/identity, triggers/functions và metadata cần phục hồi.
- Giữ backup ngoài Git, hạn chế truy cập. Chốt retention, RPO/RTO, owner và quy trình khôi phục.
- Restore vào project/database cô lập; đối chiếu counts, schema/security metadata, ownership/FK và khả năng đọc trước khi phê duyệt DDL.
- **Stop:** không có backup xác nhận hoặc restore rehearsal thất bại thì không chạy DDL/backfill.

### Pha 2 — Staging rehearsal (DDL + writes chỉ trên staging)

- Tạo target tables/mapping/policies/indexes additive trên staging từ migration version được review; legacy objects staging giữ nguyên.
- Nếu legacy counts vẫn 0, không backfill. Nếu có rows, chỉ backfill sau khi mapping từng field mơ hồ được chủ dự án duyệt; raw source giữ nguyên.
- SQL dry-run là các SELECT aggregate/validation checks được review trước và sau; không chạy `EXPLAIN ANALYZE` vì nó thực thi query. Không tạo production SQL trong task tài liệu này.
- Backfill phải idempotent, có checkpoint và error/unresolved accounting; uniqueness/mapping conflict dừng batch, không overwrite.
- Kiểm tra cross-user A/B, ownership filter Express, RLS flags/policies, grants, UUID/PK/FK, response DTO, tags containment, date filters, timestamp validation, duration server calculation và delete cascade trên fixtures riêng.

### Pha 3 — Production additive DDL/backfill (phê duyệt riêng)

- Chỉ sau khi staging, backup/restore, mapping decisions, rehearsal, lock/runtime estimate và owner approvals đạt.
- Recheck counts/metadata ngay trước chạy. DDL chỉ tạo target structures, policies/indexes/mapping objects đã review; không drop/rename/alter legacy fields hoặc grants.
- Nếu counts khác preflight đã duyệt, stop trước backfill. Mọi data write chạy theo batches có checkpoint và reconciliation; bảo toàn raw legacy source.
- Không thực hiện pha này trong Đợt 8E.3.

### Pha 4 — Cutover và rollback

- Cutover API source sang target tables trong rollout riêng; có maintenance/freeze hoặc consumer compatibility plan cho mọi legacy writer.
- Trước khi target nhận writes: có thể rollback route/config về legacy behavior; không đổi/xóa legacy objects.
- Sau khi target nhận writes: rollback không được bỏ target tables hoặc target rows. Dùng forward-fix hoặc route rollback tới một API version vẫn đọc target; không hứa rằng API legacy có thể biểu diễn đầy đủ record mới.
- Duy trì target + legacy + mapping trong thời gian quan sát. Cleanup/drop/rename là migration riêng, destructive risk, cần backup mới và approval rõ ràng.

## 8. Reconciliation gates và điều kiện dừng

Trước khi migration/backfill tiếp tục, reconcile:

- Legacy source counts, target counts, mapped/unresolved/error counts. Nếu source count không bằng snapshot/preflight expectation, dừng và điều tra.
- Số UUID target duy nhất; một legacy key ánh xạ tối đa một UUID và một target UUID không trỏ nhiều legacy keys ngoài rule được duyệt.
- Owner FK/orphan counts; mọi user mapping phải giữ đúng owner. Không xuất UUID/user identifiers trong báo cáo chia sẻ.
- Field-level counts/comparison và checksum có kiểm soát; `tags`, ngày, timestamps, quality và stages không được chuyển nếu unresolved.
- Sleep duration tính từ timestamp hợp lệ theo Express phải được so sánh với duration legacy; mọi mismatch báo cáo, không ghi đè âm thầm.
- RLS/policy/grants, cascade, indexes, API response validation và cross-account tests đạt trên staging.

**Dừng ngay** khi có count delta chưa giải thích, orphan owner, mapping duplicate, dữ liệu parse mơ hồ, constraint/policy/grant drift, backup/restore failure, test ownership failure, query error hoặc migration duration/lock vượt ngưỡng đã duyệt. Không bỏ qua lỗi bằng default hoặc xóa rows.

## 9. Các quyết định và điều kiện còn chờ

- Chủ dự án review/chấp thuận phương án B (chỉ đề xuất; chưa phê duyệt migration/cutover).
- Chốt naming target/mapping tables và exact grants cho Express-only access; giữ nguyên legacy grants.
- Chốt consumer inventory, legacy write freeze/maintenance window và rollout API version.
- Nếu preflight phát hiện rows mới: tags delimiter/escaping, `dream_date` source/remediation, sleep time format/timezone/DST, quality mapping, stage unknown handling, notes handling và row unresolved policy.
- Chốt backup method, RPO/RTO, retention, restore owner, staging environment, reconciliation thresholds và cutover/rollback owner.
- Migration executable, production DDL/backfill, policy/grant changes và cleanup cần approval riêng.

## 10. Phạm vi Đợt 8E.3

Chỉ cập nhật tài liệu dựa trên inventory được cung cấp và source/contract đã review. Không đọc/sửa `.env` hoặc `server/.env`; không kết nối/chạy SQL/backup/restore/migration; không sửa Flutter, Express, API, schema, policies, grants hoặc dữ liệu; không commit/push. Inventory live được ghi nhận là snapshot; không chạy lại trong đợt này.

## 11. Đợt 8E.4 — SQL draft cho target tables (chưa thực thi)

File `supabase/migrations/DRAFT_ONLY_create_api_v2_tables.sql` là DDL dự thảo tạo mới `public.dreams_v2` và `public.sleep_records_v2`. Tên file cố ý không theo dạng version timestamp; vẫn phải coi là DDL có thể thực thi và không chạy trước review/phê duyệt riêng. File không đụng vào legacy tables, không backfill, không tạo mapping table và không chứa DROP/TRUNCATE/RENAME.

| Target | Cột và quy tắc chính |
|---|---|
| `dreams_v2` | UUID PK `id` với `gen_random_uuid()`; FK `user_id` tới `auth.users(id) ON DELETE CASCADE`; title/content/emotion text; tags `text[]` default mảng rỗng; clarity integer default 3, giới hạn 1–5; lucid boolean default false; dream_date DATE; created_at timestamptz default now(). Có checks độ dài title/content, emotion theo validator Express và tags không chứa NULL element. |
| `sleep_records_v2` | UUID PK; FK owner cascade; start/end timestamptz; duration integer NOT NULL do Express ghi; quality integer 0–100; ba stage minutes integer default 0, không âm; notes text NOT NULL default rỗng; created_at timestamptz default now(). Checks end sau start, không quá 24 giờ, duration bằng floor(elapsed/60s), duration 0–1440. |

Hai bảng bật RLS (không FORCE) và mỗi bảng có SELECT/INSERT/UPDATE/DELETE policy cho `authenticated`, luôn so sánh `user_id = auth.uid()`; UPDATE kiểm tra cả USING và WITH CHECK. Do kiến trúc CRUD qua Express, draft revoke quyền bảng từ PUBLIC/anon/authenticated và chỉ grant SELECT/INSERT/UPDATE/DELETE cho `service_role`. Service-role bypass RLS; Express vẫn phải lấy `user_id` từ JWT đã xác minh và giới hạn mọi truy vấn theo owner. Không có sequence grants vì IDs là UUID. PK index tự sinh; thêm index owner+created cho list ordering, owner+dream_date, GIN tags và owner+start_time cho filter; không có index legacy nào bị thay đổi.

Validation được đối chiếu với `server/src/validation.js`: emotion enum, clarity 1–5, sleep quality 0–100, stages không âm, timestamp timezone-aware được Express chuẩn hóa, duration do Express tính. DB duration check bảo vệ tính nhất quán nhưng không thay validation/API. DB check độ dài không thể thay thế đầy đủ `trim()` của JavaScript; server vẫn là nguồn validation. Chưa áp đặt quan hệ tổng các sleep stages với duration vì API không yêu cầu.

**Compatibility blocker:** Express routes hiện vẫn gọi `dreams`/`sleep_records`, không gọi `*_v2`. Không có route nào tự chuyển sang các bảng mới do draft này. Trước expose cần backend rollout riêng, kiểm thử ownership với `adminClient`/service_role, cập nhật account-data deletion (hiện chỉ xóa legacy và không atomic), và xác minh API filters/response. Chưa xác định có cần bật direct authenticated GRANT trong tương lai; theo kiến trúc hiện tại không cấp quyền direct client.

**Còn cần review/phê duyệt:** tên bảng; việc giữ chính xác các DB defaults; emotion CHECK vocabulary; grants service_role; index set; RLS behavior khi gọi service_role; staging run; preflight counts (snapshot 0/0 phải recheck); backup/restore rehearsal; migration version/environment/owner; API cutover/account deletion/rollback. Không có mapping/backfill trong draft, nên unresolved legacy tags/date/timezone/quality/stages không được tự chuyển đổi.

Kiểm tra trong Đợt 8E.4 chỉ là review tĩnh SQL và đối chiếu validator/routes/contract; không xác nhận SQL đã được PostgreSQL chạy, không kết nối Supabase và không thực hiện bất kỳ DDL/DML nào.
