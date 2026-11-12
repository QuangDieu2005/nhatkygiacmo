# Dream Diary — kiểm toán trước tích hợp Supabase

Ngày kiểm toán: 2026-11-13. Nhánh: `main`. Phạm vi: đọc mã nguồn/tài liệu và chạy kiểm tra Flutter; không kết nối Supabase, không đọc `.env`/`server/.env`, không sửa mã ứng dụng, backend, SQL hay dữ liệu. Chỉ báo cáo này và `TASK_LOG.md` được cập nhật.

## 1. Kiến trúc hiện tại

Kiến trúc đích đã chọn là **Flutter → Node.js/Express REST API → Supabase Auth/PostgreSQL**. Express dùng Supabase Auth để xác minh access token; các truy vấn nghiệp vụ hiện dùng `adminClient` và lọc theo `req.user.id`. SQL bật RLS owner policies làm lớp bảo vệ bổ sung.

Implementation Flutter hiện chưa đi theo luồng đích: UI gọi Provider → Repository fixture/in-memory. `ApiService` chỉ có mock/stub; `ApiClient` được khởi tạo nhưng không được gọi trong các CRUD hiện tại. `supabase_flutter` có trong dependencies nhưng chưa khởi tạo và không được dùng cho CRUD. Backend có routes thật theo source code, nhưng chưa xác minh chạy với dự án Supabase này.

## 2. Tình trạng chức năng

| Khu vực | Hiện trạng | Phân loại / ghi chú |
|---|---|---|
| Login | Form/validation/loading hoạt động với mock; mọi thông tin hợp lệ được mock chấp nhận | Hoàn thành UI với mock; chưa xác thực thật |
| Register | Mock trả user; Provider cố ý vẫn unauthenticated | Hoàn thành UI với mock; không tạo tài khoản hoặc xác nhận email thật |
| Forgot password | Mock delay; UI nói rõ email không được gửi | Chưa triển khai backend thật; route recovery/reset chưa có |
| Khôi phục auth | `AuthProvider.checkAuthStatus()` khởi tạo từ `DreamDiaryApp`; service đọc user/token từ SharedPreferences | Mock persistence; không kiểm tra token với server/refresh |
| Logout | Xóa local user/token và cờ đăng nhập | Không gọi `/auth/logout`, nên chưa thu hồi phiên phía Auth |
| Dreams list/search/filter/detail | CRUD/filter/search, tải theo ID, retry và state có trong Provider/UI | Hoàn thành với repository mock cục bộ; API chưa nối |
| Add/Edit/Delete dream | Repository in-memory thêm/sửa/xóa; dữ liệu không bền vững qua process restart | Hoàn thành với mock |
| Sleep tracking | Active/pending snapshot lưu SharedPreferences; retry, restore và upsert theo ID có unit/widget coverage | Có thể giữ nguyên logic local đã ổn định; chưa đồng bộ API |
| Sleep history/statistics | Repository fixture; thống kê tính phía client, gồm streak và số giấc mơ mẫu | Mock; stage ngủ là ước lượng. `currentStreakDays`/mặc định dream count chưa tính từ dữ liệu thật |
| Home/Analytics/History | Loading/error/empty và retry riêng cho nguồn dữ liệu đã có; phụ thuộc Provider/repository local | Hoàn thành UI với mock; phải thay nguồn dữ liệu có kiểm soát khi tích hợp |
| Profile / mục tiêu ngủ | Mục tiêu cập nhật UserModel và SharedPreferences khi có user; chưa có profile API/table | Local-only |
| Notifications | Plugin được init/request permission; có hàm gửi một notification thủ công | Chưa thấy lập lịch nhắc giờ ngủ; switch chỉ lưu bool trong UserModel, không bật/tắt lịch thông báo |
| Avatar, ngôn ngữ, theme | Avatar là icon/nút camera tĩnh; language và dark theme hiển thị trạng thái tĩnh | Chưa có thao tác thay đổi thực |
| Backend health/Auth/CRUD | Routes Express có trong source và gọi Supabase client | Đã có backend code nhưng chưa có kiểm thử/API client Flutter; không xác nhận hoạt động với Supabase |

## 3. Sai lệch hợp đồng dữ liệu

| Đối tượng | Flutter model / repository | Flutter API client | Express API | PostgreSQL schema | Data contract mục tiêu |
|---|---|---|---|---|---|
| Dream ID | `DreamModel.id` là `String`; fixture ID dạng `dream_01` | Chưa gọi; từ `fromJson` yêu cầu String | Parse path bằng `Number`, yêu cầu bigint dương | `bigint identity` | UUID; server sinh; path UUID |
| Dream owner | `userId`, `fromJson` fallback `default_user`; fixtures `user_01` | Chưa gửi request | Insert lấy `req.user.id`, truy vấn owner-scoped | UUID FK Auth | UUID chỉ từ JWT, không tin client |
| Dream fields | Có title/content/emotion/tags/clarity/isLucid/dreamDate/createdAt | CRUD stub; serializer model gửi tất cả gồm `id/user_id/created_at` | Chỉ chấp nhận title/content/emotion/tags; không validate/ghi các trường clarity/lucid/date | Chỉ title/content/emotion/tags text/created_at | Thêm clarity 1..5, lucid, dream_date DATE; tags `text[]` |
| Dream date | `toIso8601String()` trên DateTime; từ model có thể giữ giờ/offset | Chưa có quy tắc date-only | Không nhận field | Không có cột | JSON `YYYY-MM-DD`, ngày lịch không bị đổi do UTC |
| Dream tags/search | `List<String>` và tìm substring client-side | Chưa gọi | Query hiện dùng `tags.ilike` và free-text q | `tags text` | `text[]`; tag query dùng containment, không dùng `ilike`; q mặc định title/content |
| Sleep ID | `String`; fixtures `session_1`; tracking ID dạng `session_<milliseconds>` | Stub nhắc `/sleep-sessions` | ID parse bigint; actual collection `/sleep-records` | `bigint identity` | UUID, client giữ String |
| Sleep fields | Model có UTC-capable DateTime, duration, quality 0..100, stages, notes, isTracking | `toJson()` gửi `user_id`, `duration_minutes`, `is_tracking`, ngoài contract | Dùng `sleep_time`, `wake_time`, `duration_minutes`, `quality` 1..10, `note`; duration do client cung cấp | Cùng cột legacy; không stages/start/end timestamps | `start_time/end_time` TIMESTAMPTZ, quality 0..100, stage fields, notes; Express tự tính duration và không tin client |
| Auth response | AuthService mong `{user, token}`; `UserModel.fromJson` mong `id/email/name/...` | Login/register chưa gọi Dio | Login/register trả `{user, session}` và token chuẩn Supabase | Identity ở `auth.users` | DTO `{user, session}` với access/refresh/expiry; `session:null` nghĩa pending confirmation |
| Config | `apiBaseUrl` hardcode `localhost:5000` | Dio chưa gắn bearer, chưa refresh | Port mặc định 3000, prefix `/api` | — | URL theo platform; Bearer access token, refresh flow rõ |

Ngoài ra: `DreamRepository` và `SleepRepository` là singleton fixture/in-memory; thay bằng API cần giữ giao diện repository, parse DTO nghiêm ngặt, phân trang chưa có ở bản đầu. API spec xác định GET list là JSON array trực tiếp.

## 4. Authentication và bảo mật

### Luồng hiện tại

- `DreamDiaryApp` gọi `AuthProvider.checkAuthStatus()` khi tạo provider. Splash chạy delay 2,4 giây rồi tự đọc `prefIsLoggedIn`; hai cơ chế khởi động độc lập, không đợi trạng thái Provider và có thể lệch nhau.
- `GoRouter` chưa có `redirect`/route guard hay `refreshListenable`. Màn Home, shell tabs và màn con có thể mở trực tiếp khi chưa đăng nhập. UI login không phải biên bảo mật.
- `AuthService` lưu mock token và User JSON qua SharedPreferences. Không có expiry, refresh, xác minh session hoặc single-flight retry. Logout chỉ xóa local values; backend logout cần bearer nhưng chưa được gọi.
- Signup mock không biểu diễn `confirmation_required`; provider hiện không xác thực sau register. Backend hỗ trợ 202 với `session: null`, nhưng client chưa có mô hình pending confirmation.
- `/auth/forgot-password` và `/auth/reset-password` chưa được triển khai trong Express.

### Findings theo mức độ

| Mức | Phát hiện và bằng chứng | Khuyến nghị trước/đến khi tích hợp |
|---|---|---|
| **P0 — trước phát hành/tích hợp credentials** | `pubspec.yaml` liệt kê `.env` như asset Flutter; metadata filesystem xác nhận `.env` đang tồn tại nhưng không được Git track. Nếu file chứa giá trị riêng tư, Flutter bundle có thể đóng gói nó. Không đọc nội dung theo yêu cầu bảo mật. | Xác minh an toàn nội dung ngoài audit; không để secret trong Flutter env; chỉ đưa cấu hình public cần thiết vào app và bỏ env nhạy cảm khỏi assets/build. Anon/publishable key vẫn không phải service-role nhưng cần RLS. |
| **P0 — trước bật dữ liệu thật** | Không có route guard; splash dùng boolean local thay vì trạng thái session đã xác minh; logout chỉ local. | Thiết kế guard đồng bộ với AuthProvider, session restoration và xác thực token; xác định behavior offline/expired trước khi mở dữ liệu cá nhân. |
| **P0 — trước CRUD thật** | DB/API/model không tương thích về ID, tên/kiểu cột và field. Request từ client hiện tại không thể dùng an toàn với backend/schema hiện tại. | Chốt contract và migration versioned/backup/rollout trước khi bật endpoint thật; thực hiện test contract. |
| **P1 — trong tích hợp auth** | Token lưu SharedPreferences dạng thường; chưa refresh, expiry, revoke logout, pending email confirmation. | Secure storage theo nền tảng và thiết kế web riêng; refresh rotation/401 single-flight; xử lý pending confirmation/forgot/reset; không log token. |
| **P1 — trong tích hợp server** | CORS mặc định `*`; health trả `error.message` upstream; auth routes trả nguyên message upstream; global handler log Error object. | Allowlist origins deploy; response lỗi sanitize; log có redact; cấu hình rate limit auth riêng và theo dõi abuse. |
| **P1 — integrity/authorization** | Service-role bypass RLS; các route dreams/sleep hiện lọc theo `req.user.id`, đây là điểm tốt. SQL bật owner policies cho CRUD. Cần test account isolation và update/delete miss => 404. | Giữ owner filter trong mọi truy vấn/mutation; thêm test RLS/API đa tài khoản. Không dựa vào việc bật RLS nếu đang dùng service-role. |
| **P1 — data deletion** | `DELETE /api/account/data` xóa dreams rồi sleep bằng hai request riêng, không atomic; lỗi bước hai có thể để lại trạng thái xóa một phần. | Nếu đưa chức năng này ra UI, dùng transaction/RPC hoặc quy trình idempotent có kết quả một phần rõ ràng; cân nhắc re-auth. Hiện Profile chưa expose chức năng này. |
| **P2 — UX/ops** | Profile setting controls phần lớn chưa có hành vi; notification scheduling chưa có; API chưa có health check client/observability; chưa có backend automated tests thấy trong repo inventory. | Hoàn thiện theo sản phẩm sau luồng Auth/CRUD; bổ sung test contract, migration staging và monitoring. |

`server/.env` cũng hiện diện nhưng không được mở; `.gitignore` loại trừ `.env`, `.env.*` và allowlist `.env.example`. `.env.example` chỉ kiểm tra tên biến, không in giá trị; server example khai báo tên `SUPABASE_ANON_KEY`, root example dùng `SUPABASE_PUBLISHABLE_KEY`, cần chuẩn hóa tên config. `supabase_schema.sql` cấp quyền CRUD role authenticated và policies owner; backend service-role bypass policies như tài liệu đã nêu.

## 5. Công việc còn lại

### P0 — trước tích hợp dữ liệu người dùng

1. Xử lý nguy cơ `.env` được đóng gói trong Flutter asset; xác nhận không có private key/secret phía client.
2. Chốt và triển khai migration được phê duyệt để schema, Express, model/DTO cùng contract; không cast bigint sang UUID trực tiếp và không tự suy diễn dữ liệu cũ.
3. Thêm auth route guard/khôi phục session dựa trên session hợp lệ; khóa dữ liệu cá nhân khi unauthenticated.
4. Thêm contract tests cho toàn bộ payload/response và kiểm tra phân quyền user isolation trước khi bật client thật.

### P1 — trong đợt tích hợp

1. Chuẩn hóa Auth DTO, email confirmation, secure token storage, refresh/expiry/logout và forgot/reset.
2. Cập nhật ApiClient base URL theo platform, Bearer injection, lỗi, timeout, refresh có giới hạn.
3. Cập nhật Dream DTO/validation/search tags[]/UUID/date-only và full CRUD owner-scoped.
4. Cập nhật Sleep completed-session contract: UTC offset-required timestamps; Express tính duration; UUID upsert/idempotency; map quality/stages/notes.
5. Bảo vệ CORS, sanitize lỗi/health, logging redact, rate-limit auth; cân nhắc atomic account-data deletion.
6. Chỉ đổi Repository sang API sau khi serializers/contracts có test; giữ fixtures trong unit/widget test.

### P2 — sau luồng cốt lõi

1. Quyết định profile/settings/avatar/language/theme/notification scheduling và persistence.
2. Thống nhất định nghĩa streak, tổng mơ, chart range/timezone và tính analytics từ dữ liệu thật.
3. Pagination, tối ưu query/index, telemetry/monitoring và UX phục hồi mạng.

## 6. Lộ trình tích hợp đề xuất

1. Chốt hợp đồng còn mở; inventory schema/data hiện có, backup/restore và staging. Soạn migration versioned rồi review/phê duyệt riêng; chưa chạy trong audit.
2. Hoàn thiện schema đích, RLS/policies/grants; chạy kiểm thử owner isolation trên staging.
3. Hoàn thiện Express Auth/JWT, validation, rate limit, CORS, lỗi an toàn; thêm route tests.
4. Hoàn thiện Dream và Sleep API/DTO/UUID/owner scope; kiểm thử timestamp, duration server-side, tags containment, CRUD và retry/idempotency.
5. Tích hợp Flutter Auth trước, gồm session null/email confirmation, persistence an toàn, refresh, guard và logout.
6. Tích hợp Dream CRUD qua `DreamDataRepository`, rồi Sleep CRUD qua `SleepSessionRepository`; giữ active tracking local ở bản đầu.
7. Chuyển Home/Analytics/History sang API, xác minh giữ dữ liệu từng nguồn và thống nhất công thức thống kê.
8. Kiểm thử đa tài khoản, expired/refresh token, logout/revoke, CRUD ownership/RLS, migration staging và mục tiêu build nền tảng.

## 7. Kiểm tra chất lượng và giới hạn

- Flutter SDK: 3.47.0 stable; Dart 3.13.0.
- `flutter analyze --no-pub`: hoàn tất, 101 issues đều là **info**, 0 warning, 0 error; lệnh exit 1 vì analyzer trả non-zero khi còn diagnostics.
- `flutter test --reporter expanded`: **47/47 passed**, exit 0.
- `git diff --check`: sẽ được ghi nhận sau khi thêm báo cáo và TASK_LOG.
- Chưa chạy server, Node tests (repo không khai báo script test), không gọi API, không xác thực kết nối Supabase, không chạy integration test database hay kiểm thử xâm nhập.
- Test Flutter hiện tập trung widget/state (auth UI, data states, detail record, responsive, sleep tracking, smoke); không chứng minh API/Auth/database hoạt động.
- Không kiểm tra trực quan trên thiết bị thật/emulator trong audit này.

