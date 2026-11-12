# Hợp đồng dữ liệu đề xuất — Dream Diary

**Trạng thái:** Hợp đồng đã được chuẩn hóa trong Flutter API serialization và Express routes tại Đợt 8A.2. Chưa chạy/kết nối Supabase; `supabase_schema.sql` vẫn là schema legacy nên database chưa tương thích cho tới khi có migration được duyệt.

## Quy ước chung

- JSON dùng `snake_case` trên wire để khớp PostgreSQL. Flutter giữ property camelCase và map tường minh trong `toJson/fromJson`.
- ID bản ghi và `user_id` là UUID dạng chuỗi JSON. `user_id` lấy duy nhất từ JWT đã xác minh (`req.user.id`); client không được quyết định owner.
- `created_at` do server/database sinh, UTC ISO-8601 trong JSON (`Z`). Không yêu cầu client gửi khi tạo.
- Không bỏ trường nào đang có trong model. Trường không có ý nghĩa lưu trữ (ví dụ `isTracking`) được giữ trong model/domain cục bộ nhưng không gửi như thuộc tính bản ghi.
- API trả DTO cùng shape sau khi chuẩn hóa, response lỗi `{ "message": "...", "code": "..." }`; không trả lỗi SQL, stack hoặc secret.

## Dream

| JSON/DB field | Kiểu đề xuất | Quy tắc | Ánh xạ Flutter |
|---|---|---|---|
| `id` | UUID | PK, server sinh; client bỏ qua khi POST | `String id`, UUID string |
| `user_id` | UUID | NOT NULL; server gán từ token | `String userId`, chỉ response/domain |
| `title` | TEXT | bắt buộc, trim, tối đa theo validator thống nhất (hiện app 100, API 180) | `title` |
| `content` | TEXT | bắt buộc; giới hạn thống nhất (hiện app 2,000, API 20,000) | `content` |
| `emotion` | TEXT hoặc enum có kiểm soát | bắt buộc; giá trị đúng `EmotionType.name` | `EmotionType emotion` |
| `tags` | TEXT[] | mặc định rỗng; mỗi phần tử chuỗi | `List<String> tags` |
| `clarity_score` | SMALLINT | NOT NULL, 1..5, mặc định 3 | `int clarityScore` |
| `is_lucid` | BOOLEAN | NOT NULL, mặc định false | `bool isLucid` |
| `dream_date` | DATE | NOT NULL; ngày lịch địa phương người dùng ghi nhớ giấc mơ, không đổi ngày do UTC | `DateTime dreamDate` (serialize `YYYY-MM-DD`, parse thành date-local theo quy ước app) |
| `created_at` | TIMESTAMPTZ | NOT NULL, default now(), UTC | `DateTime createdAt` |

`DATE` phù hợp vì ngày giấc mơ là ngày nhật ký, không phải một thời điểm tuyệt đối. Chốt thêm rằng Flutter gửi ngày theo lịch địa phương đang hiển thị; không dùng `toIso8601String()` nguyên trạng nếu nó làm lẫn timezone.

### Dream write/read DTO
POST/PATCH nhận `title`, `content`, `emotion`, `tags`, `clarity_score`, `is_lucid`, `dream_date`; không nhận `id`, `user_id`, `created_at`. GET/POST/PATCH trả toàn bộ trường trên cùng `id`, `user_id`, `created_at`. PATCH theo đề xuất là cập nhật toàn phần và yêu cầu đủ các trường writable; nếu muốn partial patch thì validator phải hỗ trợ rõ trường bị bỏ qua khác với `null`.

## Sleep record

| JSON/DB field | Kiểu đề xuất | Quy tắc | Ánh xạ Flutter |
|---|---|---|---|
| `id` | UUID | PK, server sinh | `String id` |
| `user_id` | UUID | NOT NULL; server gán từ JWT | `String userId` |
| `start_time` | TIMESTAMPTZ | NOT NULL; instant UTC | `DateTime startTime` |
| `end_time` | TIMESTAMPTZ | nullable khi là bản nháp đang ngủ; bản ghi hoàn tất gửi API phải có | `DateTime? endTime` |
| `duration_minutes` | INTEGER | bản ghi hoàn tất: Express tự tính từ `start_time` và `end_time`; client không gửi/không được tin giá trị này. Kết quả là số phút nguyên, giới hạn 0..1440 | `int? durationMinutes` (response/domain only) |
| `quality_score` | SMALLINT | NOT NULL, số nguyên 0..100; write API hiện yêu cầu số điểm, model/domain hiện default 75 | `int qualityScore` |
| `deep_sleep_minutes` | INTEGER | NOT NULL default 0, không âm | `int deepSleepMinutes` |
| `light_sleep_minutes` | INTEGER | NOT NULL default 0, không âm | `int lightSleepMinutes` |
| `rem_sleep_minutes` | INTEGER | NOT NULL default 0, không âm | `int remSleepMinutes` |
| `notes` | TEXT | NOT NULL default chuỗi rỗng | `String? notes` |
| `created_at` | TIMESTAMPTZ | database sinh UTC | `DateTime createdAt` |
| `isTracking` | không lưu ở record đã hoàn tất | trạng thái active chỉ cục bộ; không gửi | `bool isTracking`, giữ trong model để tương thích domain |

Lưu `start_time`/`end_time` là UTC instant trong `TIMESTAMPTZ`; JSON phải là ISO-8601 có `Z` hoặc offset rõ ràng (ví dụ `+07:00`). Express từ chối timestamp sai định dạng hoặc thiếu timezone offset, chuẩn hóa về UTC, yêu cầu `end_time > start_time`, và từ chối khoảng thời gian vượt 24 giờ. Không diễn giải timestamp thiếu timezone theo timezone máy chủ. Express tự tính `duration_minutes = floor((end_time - start_time) / 60 giây)`; khoảng thời gian dương dưới một phút có duration 0. Client không gửi duration; Express từ chối request có trường này. PATCH đổi timestamp cũng tính lại duration. UI chuyển UTC instant sang timezone thiết bị khi hiển thị. Các stage minutes hiện là ước lượng, không được trình bày như thiết bị đo.

Còn cần quyết định: cho phép ghi nhận session dưới 1 phút (hiện schema đích cho phép 0, API có thể sinh 0); quan hệ tổng stage minutes với duration (ước lượng có thể lệch do làm tròn). Write API hiện yêu cầu `quality_score` 0–100 vì model không nullable và có default 75; migration cần `NOT NULL`/default tương ứng. Không đặt constraint tổng stage = duration.

## Auth/User

- Supabase Auth là nguồn danh tính; `user_id` là `auth.users.id` UUID.
- `UserModel.id` ánh xạ `user.id`; `email`, `name` (metadata `name`), `avatarUrl`, `createdAt` ánh xạ nếu Auth trả metadata tương ứng.
- `sleepGoalHours` và `notificationsEnabled` hiện chỉ thuộc model/local settings; chưa có profile/settings table/API. Giữ các trường trong model, chưa giả định chúng được đồng bộ DB.
- Password chỉ đi qua HTTPS tới endpoint auth và Supabase Auth; không lưu trong Flutter/server/database/log.
- Session DTO backend phải thống nhất khóa Supabase: `access_token`, `refresh_token`, `expires_in`, `expires_at` (nếu có), `token_type`, cùng `user`. Không dùng khóa mơ hồ `token`.

## Bắt buộc/tùy chọn/nội bộ

- **Bắt buộc khi tạo dream:** `title`, `content`, `emotion`, `dream_date`; `tags`, `clarity_score`, `is_lucid` có mặc định nếu client bỏ qua.
- **Bắt buộc khi tạo completed sleep:** `start_time`, `end_time`, `quality_score` (số nguyên 0..100); stage minutes mặc định 0, notes tùy chọn/null chuẩn hóa chuỗi rỗng; Express tính duration từ hai timestamp đã xác thực. Client không gửi duration.
- **Chỉ server/database:** `id`, `user_id`, `created_at` trong create request.
- **Nội bộ/local:** active `isTracking`; có thể là bản nháp local trước khi hoàn thành. Các cài đặt UserModel chưa có profile API vẫn giữ cục bộ.
- **Chỉ auth:** password/refresh token không bao giờ thuộc DTO hồ sơ hoặc bản ghi nghiệp vụ.

## Các quyết định cần chủ dự án xác nhận trước triển khai

1. Giấc mơ lưu ngày lịch (đề xuất DATE) hay thời điểm chính xác (TIMESTAMPTZ)?
2. Có cần phân biệt session đang chạy được đồng bộ server giữa thiết bị hay chỉ lưu local? Đề xuất chỉ gửi session hoàn tất ở bản đầu.
3. Đã chốt cho contract hiện tại: `quality_score` là số nguyên bắt buộc 0–100, model default 75; schema đích dùng NOT NULL/default 75. Thay đổi yêu cầu nghiệp vụ cần cập nhật contract/model/schema đồng bộ.
4. Avatar/mục tiêu ngủ/notification settings có cần profile API/bảng riêng không? Chưa có schema hiện tại.
5. Quy ước ngày lịch khi thiết bị đổi timezone và khi nhập giấc mơ cũ.

## Serialization/API boundary — Đợt 8A.2

- `DreamModel.toJson/fromJson` và `SleepSessionModel.toJson/fromJson` tiếp tục giữ cho local/mock và snapshot SharedPreferences hiện hữu. Không dùng các local methods này làm API payload.
- API write dùng `toApiWriteJson()`: Dream chỉ gửi `title`, `content`, `emotion`, `tags`, `clarity_score`, `is_lucid`, `dream_date`; Sleep chỉ gửi `start_time`, `end_time`, `quality_score`, stage minutes và `notes`. Không gửi ID, owner, created time, duration hay trạng thái tracking.
- API response dùng `fromApiJson()`: xác thực UUID, các trường bắt buộc/kiểu dữ liệu, danh sách tag string, enum emotion, ngày lịch Gregorian `YYYY-MM-DD`, và timestamp ISO-8601 có timezone. Sleep timestamps parse thành UTC instant. Thiếu hoặc sai trường bắt buộc ném `FormatException`, không âm thầm dùng default local.
- Dream create/update server sinh ID, gán owner từ JWT, server sinh `created_at`; date-only được serialize từ component lịch local, không qua UTC conversion. Dream GET tag filter dùng `text[]` containment; `q` chỉ tìm title/content.
- Sleep write chỉ dành cho bản ghi hoàn tất. Client bỏ `duration_minutes`; Express tự tính từ timestamp. `isTracking` chỉ ở model/local snapshot. `quality_score` là số nguyên bắt buộc 0–100 trong API/model hiện tại; schema migration đích cần đồng bộ quyết định này.
- Đây là chuẩn hóa contract trong source; repository Flutter vẫn mock/in-memory. Schema `supabase_schema.sql` không thay đổi trong nhiệm vụ và cần migration riêng trước khi chạy API trên database hiện hữu.
