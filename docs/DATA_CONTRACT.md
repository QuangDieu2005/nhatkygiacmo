# Hợp đồng dữ liệu đề xuất — Dream Diary

**Trạng thái:** đề xuất thiết kế cho kiến trúc đã chọn Flutter → Express REST → Supabase. Chưa áp dụng vào model, API hay database. Đây là hợp đồng mục tiêu; các trường/bảng hiện tại không tương thích như nêu dưới đây.

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
| `duration_minutes` | INTEGER | bản ghi hoàn tất: 0..1440; server kiểm tra khớp thời gian hoặc tính từ start/end theo chính sách thống nhất | `int? durationMinutes` |
| `quality_score` | SMALLINT | 0..100, nullable khi chưa đánh giá hoặc có quy tắc mặc định rõ ràng | `int qualityScore` (domain hiện default 75) |
| `deep_sleep_minutes` | INTEGER | NOT NULL default 0, không âm | `int deepSleepMinutes` |
| `light_sleep_minutes` | INTEGER | NOT NULL default 0, không âm | `int lightSleepMinutes` |
| `rem_sleep_minutes` | INTEGER | NOT NULL default 0, không âm | `int remSleepMinutes` |
| `notes` | TEXT | NOT NULL default chuỗi rỗng | `String? notes` |
| `created_at` | TIMESTAMPTZ | database sinh UTC | `DateTime createdAt` |
| `isTracking` | không lưu ở record đã hoàn tất | trạng thái active chỉ cục bộ; không gửi | `bool isTracking`, giữ trong model để tương thích domain |

Lưu `start_time`/`end_time` là UTC instant; UI chuyển qua timezone thiết bị khi hiển thị. `duration_minutes` có thể lưu để snapshot/history và query thuận tiện, nhưng server phải chọn nguồn chuẩn: khuyến nghị tính từ hai timestamp khi hoàn tất, chỉ cho phép duration gửi từ client nếu sai lệch được validate. Các stage minutes hiện là ước lượng, không được trình bày như thiết bị đo.

Còn cần quyết định: cho phép ghi nhận session dưới 1 phút (hiện schema cho 0, service có thể sinh 0); quality có bắt buộc không; quan hệ tổng stage minutes với duration (ước lượng có thể lệch do làm tròn). Không tự đặt constraint chặt trước khi thống nhất nghiệp vụ.

## Auth/User

- Supabase Auth là nguồn danh tính; `user_id` là `auth.users.id` UUID.
- `UserModel.id` ánh xạ `user.id`; `email`, `name` (metadata `name`), `avatarUrl`, `createdAt` ánh xạ nếu Auth trả metadata tương ứng.
- `sleepGoalHours` và `notificationsEnabled` hiện chỉ thuộc model/local settings; chưa có profile/settings table/API. Giữ các trường trong model, chưa giả định chúng được đồng bộ DB.
- Password chỉ đi qua HTTPS tới endpoint auth và Supabase Auth; không lưu trong Flutter/server/database/log.
- Session DTO backend phải thống nhất khóa Supabase: `access_token`, `refresh_token`, `expires_in`, `expires_at` (nếu có), `token_type`, cùng `user`. Không dùng khóa mơ hồ `token`.

## Bắt buộc/tùy chọn/nội bộ

- **Bắt buộc khi tạo dream:** `title`, `content`, `emotion`, `dream_date`; `tags`, `clarity_score`, `is_lucid` có mặc định nếu client bỏ qua.
- **Bắt buộc khi tạo completed sleep:** `start_time`, `end_time`; quality/stage/notes theo mặc định/nullable đã nêu; duration tính/validate server-side.
- **Chỉ server/database:** `id`, `user_id`, `created_at` trong create request.
- **Nội bộ/local:** active `isTracking`; có thể là bản nháp local trước khi hoàn thành. Các cài đặt UserModel chưa có profile API vẫn giữ cục bộ.
- **Chỉ auth:** password/refresh token không bao giờ thuộc DTO hồ sơ hoặc bản ghi nghiệp vụ.

## Các quyết định cần chủ dự án xác nhận trước triển khai

1. Giấc mơ lưu ngày lịch (đề xuất DATE) hay thời điểm chính xác (TIMESTAMPTZ)?
2. Có cần phân biệt session đang chạy được đồng bộ server giữa thiết bị hay chỉ lưu local? Đề xuất chỉ gửi session hoàn tất ở bản đầu.
3. Quality bắt buộc 0–100 hay nullable đến khi người dùng đánh giá?
4. Avatar/mục tiêu ngủ/notification settings có cần profile API/bảng riêng không? Chưa có schema hiện tại.
5. Quy ước ngày lịch khi thiết bị đổi timezone và khi nhập giấc mơ cũ.
