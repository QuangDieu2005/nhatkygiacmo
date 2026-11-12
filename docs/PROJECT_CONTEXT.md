# PROJECT_CONTEXT — Dream Diary

Ngày rà soát: 2026-11-12. Phân tích dựa trên checkout local; không đối chiếu thay đổi mới nhất trên GitHub. Không đọc nội dung `.env`/`server/.env`.

## Tóm tắt
Ứng dụng nhật ký giấc mơ và theo dõi giấc ngủ dùng Flutter/Dart, giao diện Material 3 tối, Provider và GoRouter. Repository có một backend Express/Node.js và schema PostgreSQL/Supabase, nhưng luồng client hiện tại chưa nối backend thật: đăng nhập giả lập; giấc mơ/phiên ngủ từ repository trong bộ nhớ; phiên ngủ đang chạy và một số cài đặt dùng SharedPreferences. Tài liệu hiện có mô tả tích hợp Supabase như đã hoàn tất, không phản ánh mã hiện hành.

## Thành phần và luồng dữ liệu
- Khởi động: `lib/main.dart` tải dotenv nếu được, khởi tạo `ApiClient` và thông báo; Supabase.initialize đang comment. Sau đó `app.dart` đăng ký `AuthProvider`, `DreamProvider`, `SleepProvider`.
- UI → Provider → Repository/Service → Model. Điều hướng khai báo ở `lib/core/routes/app_router.dart`, các màn hình theo feature ở `lib/features/`.
- Auth: `AuthProvider` → `AuthService` → `ApiService.login/register` trả user/token giả → `SharedPreferences`. Khôi phục session đọc user/token đã lưu; không có xác minh token phía server. Quên mật khẩu chỉ đợi giả lập.
- Dream: `DreamProvider` gọi `DreamRepository`; repository chứa 10 mục mẫu hard-code và CRUD chỉ thay đổi list trong bộ nhớ. Dữ liệu mất khi tiến trình khởi động lại.
- Sleep: `SleepRepository` chứa 7 phiên mẫu; `SleepTrackingService` lưu phiên đang chạy trong SharedPreferences, tạo thời lượng/chất lượng và phân bổ giai đoạn bằng công thức ước lượng. Phiên hoàn tất thêm vào list trong bộ nhớ, không lưu bền.
- Analytics/history lấy từ repositories/providers hiện tại nên dựa trên fixture, không phải dữ liệu Supabase.
- `ApiClient` cấu hình Dio nhưng interceptor chưa gắn token. `ApiService` chưa gọi HTTP ở các nghiệp vụ auth/dream/sleep.
- Backend: Express dùng Helmet, CORS, rate limit, middleware kiểm JWT qua Supabase Auth; CRUD gọi Supabase bằng service-role và lọc `user_id`. Các endpoint gồm auth login/register/refresh/logout, dreams, sleep-records, health, xóa data tài khoản.
- Database theo `supabase_schema.sql`: `dreams` và `sleep_records`, khóa tới `auth.users`, index theo user/ngày, RLS select/insert/update/delete theo `auth.uid()`.

## Công nghệ
Flutter/Dart (SDK constraint `^3.13.0`), Provider, GoRouter, Dio, Supabase JS ở server, Supabase Flutter/dotenv (khai báo nhưng chưa khởi tạo), SharedPreferences, flutter_local_notifications, fl_chart. Node backend là ES modules, Express 5, `@supabase/supabase-js`, dotenv, CORS, Helmet, express-rate-limit.

## Trạng thái chức năng
### Đã có ở mức UI/logic cục bộ
- Onboarding, splash, đăng nhập/đăng ký/quên mật khẩu (màn hình); trạng thái auth mô phỏng.
- CRUD giấc mơ, tìm kiếm/lọc cảm xúc; thao tác trong bộ nhớ.
- Bắt đầu/dừng đồng hồ phiên ngủ, khôi phục phiên đang chạy cục bộ; thống kê/chart và history.
- Cài đặt mục tiêu/ngôn ngữ thông báo (?) và hồ sơ cục bộ; kiểm tra kỹ màn hình trước khi coi là hoàn chỉnh.
- Dịch vụ khởi tạo và hiển thị local notification cơ bản; lịch nhắc theo giờ chưa được xác nhận.
### Giả lập/ước lượng
- Login/register trả token giả; forgot-password không gửi email.
- 10 giấc mơ và 7 phiên ngủ seed trong code, dùng chung `user_01`.
- CRUD dream/sleep và analytics không chạm DB; danh sách ngủ không bền sau khi kết thúc phiên.
- Chất lượng ngủ dựa trên số giờ; REM/deep/light là tỷ lệ giả định, không đo từ thiết bị.
- `ApiService.fetchDreams/fetchSleepSessions` trả list rỗng; create/sync trả nguyên đối tượng.
### Chưa nối/chưa xác nhận hoạt động
- Supabase Flutter Auth/DB: chưa `initialize`; không phải đường dữ liệu mà app hiện sử dụng.
- Kết nối REST từ Flutter tới Node: chưa gọi trong `ApiService`, token interceptor rỗng, URL hằng mặc định dùng localhost:5000 trong khi backend mặc định 3000.
- Đồng bộ CRUD, reset password thực tế, xử lý refresh/session hết hạn, kiểm thử đa người dùng với backend.
- Tác vụ nhắc giờ ngủ được lên lịch và kiểm thử trên nền tảng mục tiêu.

## Phát hiện và rủi ro
1. **Mâu thuẫn kiến trúc/tài liệu:** README_SUPABASE nói Supabase Auth/DB đang hoạt động; README_BACKEND mô tả REST; mã Flutter hiện dùng mock/local. Cần chọn/ghi nhận một đường tích hợp trong giai đoạn sau, không làm thay đổi schema tùy tiện.
2. **Schema không tương thích model/API:** schema `dreams.tags` là `text`, model gửi list; API dreams nhận trường này trực tiếp. Model có `dream_date`, `clarity_score`, `is_lucid`, nhưng schema/API không lưu chúng; schema sinh `id` bigint trong khi Dart ép `id` thành String.
3. **Sleep không tương thích:** schema/API dùng `sleep_time`, `wake_time`, `quality` (1–10), `note`; Dart model dùng start/end, `quality_score` (0–100), giai đoạn ngủ và `notes`. API route `sleep-records`, trong khi Flutter stub gọi `sleep-sessions`.
4. **Auth chưa tương thích:** backend trả `session` có `access_token`/refresh token; stub Flutter kỳ vọng `token`. Signup có thể trả session null khi cần xác nhận email, còn client stub luôn giả định user/token có mặt.
5. **Rủi ro dữ liệu người dùng:** giả lập cho phép login bất kỳ email/mật khẩu; token mock được lưu SharedPreferences. Đây không phải xác thực an toàn.
6. **Cấu hình:** `server/.env.example` khai báo một Supabase URL và publishable key cụ thể thay vì giá trị mẫu; publishable key không phải service secret nhưng vẫn là cấu hình dự án. Cần thay bằng placeholder trong nhiệm vụ bảo mật riêng. API base URL mặc định Flutter lệch cổng backend; localhost không phù hợp Android emulator/điện thoại.
7. **Giai đoạn ngủ:** điểm chất lượng/REM/deep/light là ước lượng theo thời lượng, không phải cảm biến; thống kê streak đang hard-code 5 và mặc định dream count 10 khi không truyền.
8. **Kiểm thử:** `test/widget_test.dart` chỉ smoke test tối thiểu, không xác minh auth/CRUD/database; khởi tạo providers và timer có thể gây phụ thuộc thời gian trong test.
9. **Khả năng tương thích nền tảng:** thông báo và dotenv cần xác minh trên Android/iOS/web/desktop. Các thư mục assets khai báo trong pubspec nhưng chưa xuất hiện trong danh sách file; cần xác nhận build/analyzer.

## Bảo mật và dữ liệu
Schema bật RLS và chính sách owner-scoped. Backend xác minh access token, sau đó truy vấn service-role với `user_id`; nguyên tắc lọc hiện diện trong các routes. Không đọc giá trị `.env` trong lần rà soát này. `server/.env.example` có cấu hình dự án cụ thể như mô tả phía trên. Không có migration hoặc dữ liệu Supabase nào được áp dụng trong giai đoạn này.

## Giới hạn xác minh
Rà soát tĩnh các file nguồn, cấu hình, schema và tài liệu trong checkout. `flutter analyze` được yêu cầu chạy nhưng chưa có kết quả tại thời điểm lập bản ghi ban đầu; cập nhật khi tiến trình kết thúc. Không gọi Supabase, không chạy server và không kiểm tra credentials.
