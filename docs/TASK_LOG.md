# TASK_LOG — Dream Diary

## 2026-11-12 — Giai đoạn 1: phân tích và tài liệu hóa

**Yêu cầu:** đọc checkout, phân tích Flutter/Node/Supabase và tạo tài liệu. Không sửa mã app, UI hay database; không nạp dữ liệu demo.

**Đã rà soát:** cây thư mục; README và cấu hình Flutter; entrypoint, app/providers/services/repositories/models/routes; Node server, middleware/routes/Supabase client; SQL schema/RLS; widget smoke test. Không mở/in nội dung `.env` hoặc `server/.env`.

**Kết quả chính:** app Flutter hiện chạy auth giả và CRUD bằng fixtures/in-memory; phiên ngủ đang chạy lưu SharedPreferences. Backend Express và Supabase schema có hiện diện nhưng client không gọi. Model Flutter, API và schema có khác biệt field/type/endpoint. `server/.env.example` có cấu hình Supabase cụ thể, không ghi lại giá trị.

**Tài liệu tạo:** `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, `docs/DEVELOPMENT_PLAN.md`, `docs/TASK_LOG.md`.

**Xác minh:** `flutter analyze` không trả output sau khoảng 35 giây; đã dừng, không có kết quả pass/fail. Trong lúc chạy file `lib/main.dart` có thêm dòng trắng phát sinh; đã hoàn nguyên. Git status sau cùng ở giai đoạn 1 chỉ có bốn tài liệu mới. Không chạy server, không kết nối Supabase, không thực thi SQL.

## 2026-11-12 — Giai đoạn 2: chuẩn hóa kiến trúc và hợp đồng dữ liệu (tài liệu)

**Phạm vi:** kiến trúc Flutter → Express → Supabase; đối chiếu models/schema/routes/auth/config; không sửa source, schema hoặc database.

**Đã đọc:** AGENTS.md, PROJECT_CONTEXT, DEVELOPMENT_PLAN, TASK_LOG; DreamModel, SleepSessionModel, UserModel, AuthService/AuthProvider, ApiService/ApiClient/constants; Express auth/dream/sleep/middleware/server/Supabase client; schema SQL; `.env.example` và quy tắc `.gitignore` (không mở `.env` thật).

**Tài liệu tạo/cập nhật:** thêm `docs/DATA_CONTRACT.md`, `docs/API_SPECIFICATION.md`, `docs/DATABASE_MIGRATION_PROPOSAL.md`; cập nhật `docs/PROJECT_CONTEXT.md`, `docs/DEVELOPMENT_PLAN.md`, `docs/TASK_LOG.md`.

**Kết quả:** thống nhất kiến trúc đích REST qua Express; đề xuất UUID IDs, tags text[], dream_date DATE, sleep timestamps UTC, quality 0–100. Mô tả endpoint hiện hữu và endpoint auth recovery còn thiếu; quy tắc confirmation pending/session null, refresh, token storage, ownership/RLS, CORS và URLs theo nền tảng. Ghi rõ migration dữ liệu cũ cần inventory; không suy đoán timezone/delimiter/consumer.

**Giới hạn/quyết định mở:** chưa biết có dữ liệu thật và client phát hành nào phụ thuộc bigint/legacy columns; chưa chốt quality nullable, active sleep sync, profile settings, pagination response và quy tắc ngày khi đổi timezone. Xem ba tài liệu mới để biết alternatives/impact.

**Xác minh:** chỉ đọc tĩnh và kiểm tra tên env keys/ignore rules. Không chạy test/analyzer/backend, không mở env thật, không gọi Supabase, không chạy SQL/migration. Source, `supabase_schema.sql` và database không được sửa.

## 2026-11-12 — Rà soát hoàn thiện tài liệu Giai đoạn 2

- Cập nhật `AGENTS.md`: Giai đoạn 1/2 hoàn thành; phạm vi là chuẩn bị tích hợp thật; giữ nguyên quy tắc bảo mật và không tự chạy migration.
- Đồng bộ `DATA_CONTRACT.md`, `API_SPECIFICATION.md`, `DATABASE_MIGRATION_PROPOSAL.md`: Express là nguồn tính `duration_minutes` bằng floor từ timestamp sau validation; client không gửi duration. Timestamps bắt buộc ISO-8601 có `Z`/offset, được chuẩn hóa UTC; reject thiếu timezone, end <= start, khoảng >24 giờ. PATCH timestamp cũng tính lại duration.
- Tags `text[]`: bỏ đề xuất `tags.ilike`; `tag` exact-match dùng array containment, free-text `q` tìm title/content. Tìm substring trong tags nếu cần về sau thì dùng RPC/function có kiểm soát.
- GET dreams/sleep bản đầu thống nhất JSON array trực tiếp; pagination envelope hoãn lại và có thể bổ sung theo contract/version sau.
- Cập nhật context/plan/migration proposal để không còn quyết định mâu thuẫn.
- Xác minh bằng rà soát tĩnh và `git diff --check`; không chạy source/test/server, không đọc `.env`, không kết nối/chạy SQL Supabase. Chỉ tài liệu thay đổi; không sửa Flutter, backend, schema hoặc database.

## 2026-11-12 — Giai đoạn 3A, đợt 1: design system và trang chủ

- Đọc lại hướng dẫn dự án, context/plan/log, theme, màu sắc, constants, shared widgets và HomeScreen.
- Tinh chỉnh palette tối Night Sky, gradient, typography/theme cho card/button/input; thiết kế lại home header, card tổng quan ngủ, quick actions, chart tuần và recent dreams. Giữ các provider, route, dữ liệu mẫu và điều hướng hiện có; thêm empty/loading states và giới hạn chiều rộng để giảm nguy cơ tràn trên mobile.
- File source sửa: `lib/core/constants/app_colors.dart`, `lib/core/theme/app_theme.dart`, `lib/features/home/presentation/home_screen.dart`.
- `flutter analyze` và `dart analyze` đều không trả output trong 30 giây, đã dừng; chưa có kết quả analyzer. `dart format` cũng không phản hồi trong 30 giây, đã dừng. Không thể xác nhận bằng chạy app/layout thực tế trong môi trường hiện tại.
- Không thêm package, không kết nối Supabase, không sửa backend/schema/database. Các tài liệu giai đoạn 2 đã có thay đổi chưa commit từ nhiệm vụ trước; task này không chỉnh sửa nội dung các tài liệu đó ngoài log.
- Thử lại `flutter analyze --no-pub`; tiếp tục không output sau 30 giây và đã dừng. Flutter/Dart CLI trong môi trường này không phản hồi đủ để xác minh compile/layout; không chạy ứng dụng.

## 2026-11-12 — Đợt 2: giao diện danh sách giấc mơ

- Rà soát yêu cầu đính kèm, tài liệu hướng dẫn/context/plan/log và các file Dreams feature, Provider, model, routes và shared widgets.
- Làm lại màn danh sách theo AppColors/AppTheme hiện có: header có mô tả và nút thêm, ô tìm kiếm có xóa nhanh, filter chips theo EmotionType và số lượng, danh sách sliver có refresh, trạng thái loading/empty/no results/error và retry.
- Thêm `dream_list_card.dart` dành riêng cho màn danh sách để không làm đổi card mà Home dùng; hiển thị title/content rút gọn, ngày giấc mơ, cảm xúc, tags, lucid và clarity. Tap vẫn mở route chi tiết.
- Giữ Provider, GoRouter, model, repository, dữ liệu mẫu và CRUD; không thêm package.
- File sửa/tạo trong đợt này: `lib/features/dream_diary/presentation/dream_list_screen.dart`, `lib/features/dream_diary/presentation/dream_list_card.dart`, `docs/TASK_LOG.md`.
- `dart format` và `flutter analyze --no-pub` đều không có output sau 30 giây; đã dừng theo hướng dẫn. Không thể kết luận pass/fail hoặc xác minh layout trên thiết bị. Không chạy app do Flutter/Dart CLI không phản hồi.
- `git diff --check` được chạy sau khi cập nhật. Không sửa backend, Supabase, SQL schema hay database.

## 2026-11-12 — Đợt 3: thiết kế form thêm/chỉnh sửa giấc mơ

- Đọc yêu cầu đính kèm, AGENTS/context/plan/log/data contract và đối chiếu Add/Edit screen, model, validators, Provider, repository, AppTextField/AppButton và date formatter.
- Thêm `dream_form_widgets.dart` dùng chung: scaffold có nút lưu cố định, intro, date picker theo theme (không chọn tương lai), emotion chips từ `EmotionType`, slider độ rõ, lucid switch card và tag editor hỗ trợ Enter/thêm/xóa.
- Đồng bộ hai form với validation title/content, hints, bố cục cuộn và keyboard dismiss. Thêm chặn lưu lặp, loading, mounted checks và snackbar cho kết quả thành công/thất bại.
- Màn Edit khởi tạo từ bản ghi tìm thấy; khi lưu dùng `original.copyWith(...)`, giữ nguyên `id`, `userId`, `createdAt` và tags hiện hữu nếu không bị người dùng xóa. Không tạo fallback bản ghi rỗng khi không tìm thấy ID.
- File tạo/sửa: `lib/features/dream_diary/presentation/dream_form_widgets.dart`, `lib/features/dream_diary/presentation/add_dream_screen.dart`, `lib/features/dream_diary/presentation/edit_dream_screen.dart`, `docs/TASK_LOG.md`.
- `dart format` và `flutter analyze --no-pub` mỗi lệnh không phản hồi sau 30 giây; đã dừng, chưa có kết quả pass/fail. Không chạy ứng dụng do CLI không phản hồi. `git diff --check` được chạy sau đó.
- Không thêm package, không thay model/provider/repository, không kết nối Supabase; không sửa backend, SQL schema hoặc database.

## 2026-11-12 — Đợt 4: thiết kế lại màn hình chi tiết giấc mơ

- Rà soát prompt Đợt 4, tài liệu kiến trúc/hướng dẫn/log và detail/list/add/edit screens, form widgets, model, Provider, AppColors/AppTheme, routes.
- Thiết kế lại `dream_detail_screen.dart` theo Night Sky: hero title/date, card cảm xúc, clarity/lucid insight cards, nội dung đầy đủ có thể chọn, tags có giới hạn bề rộng và thời điểm tạo; bố cục cuộn, giới hạn max width cho màn rộng, trạng thái không tìm thấy.
- Bổ sung action bar sửa/xóa; giữ route edit. Hộp xác nhận xóa theo theme; khóa thao tác trong khi xóa, kiểm tra kết quả `deleteDream`, mounted checks, chỉ pop và báo thành công khi xóa thành công; báo lỗi và giữ màn hình khi thất bại.
- File sửa: `lib/features/dream_diary/presentation/dream_detail_screen.dart`, `docs/TASK_LOG.md`.
- `dart format lib/features/dream_diary/presentation/dream_detail_screen.dart` và `flutter analyze --no-pub` đều không phản hồi sau 30 giây; đã dừng, chưa có kết quả pass/fail. Không chạy ứng dụng; runtime layout chưa được xác minh.
- `git diff --check` được chạy sau khi ghi log. Không sửa model/provider/repository/routes, backend, Supabase, SQL schema hay database.

## 2026-11-12 — Đợt 5: thiết kế lại Analytics giấc ngủ

- Đọc yêu cầu Đợt 5, hướng dẫn dự án, context/plan/data contract/task log, theme/màu sắc; rà soát AnalyticsScreen, SleepProvider, SleepRepository, SleepSessionModel, SleepStatisticsModel và route GoRouter. Analytics hiện ở `/analytics`; route/Provider không đổi.
- Thiết kế lại `analytics_screen.dart` theo Night Sky: header giới thiệu, lưới chỉ số responsive, biểu đồ cột thời lượng, biểu đồ điểm chất lượng 0–100, biểu đồ tròn giai đoạn ngủ và ghi nhận dữ liệu đơn giản.
- Các chỉ số hiện được tính từ danh sách phiên ngủ đã hoàn tất: thời lượng trung bình, điểm chất lượng trung bình, số đêm, phiên dài nhất. Biểu đồ dùng tối đa 7 ngày có bản ghi; giai đoạn ngủ chỉ tổng hợp các phiên có số phút stage được ghi nhận. Loading/empty state và pull-to-refresh được giữ trong phạm vi khả năng của Provider. Không thêm chẩn đoán hay nhận định sức khỏe.
- Không sửa model, repository, Provider, route, dependency, backend, Supabase, schema hoặc database; không thêm package. Không commit/push.
- Kiểm tra: `dart format lib/features/analytics/presentation/analytics_screen.dart` và `flutter analyze --no-pub` đều không có output sau 30 giây, đã dừng theo yêu cầu; chưa xác minh được kết quả format/analyze hoặc layout runtime. Provider chưa expose error state nên UI không thể phân biệt lỗi tải với dữ liệu rỗng. `git diff --check` hoàn tất, không phát hiện whitespace error (chỉ có cảnh báo Git về chuyển LF sang CRLF).

## 2026-11-12 — Đợt 6: thiết kế lại màn hình theo dõi giấc ngủ

- Đọc prompt Đợt 6, `AGENTS.md`, context/plan/data contract/API spec/task log, AppColors/AppTheme; rà soát SleepTrackingScreen, SleepTrackingService, SleepProvider, SleepRepository, SleepSessionModel, DateFormatter, AppButton và route.
- Thiết kế lại duy nhất `lib/features/sleep_tracking/presentation/sleep_tracking_screen.dart`: trạng thái chuẩn bị ngủ, trạng thái đang theo dõi với thời gian/thời điểm bắt đầu, xác nhận kết thúc, trạng thái hoàn tất có thời lượng/giờ bắt đầu-kết thúc/điểm/stages và giữ các nút ghi giấc mơ/trang chủ. Bố cục cuộn, max width, loading/disabled affordance, thông báo lỗi UI và màu Night Sky.
- Giữ nguyên callback tracking hiện có, SleepProvider/Service/Repository/Model, SharedPreferences, route, sample data và dependencies. Không thay đổi nghiệp vụ, backend, Supabase, schema/database; không thêm package.
- Phát hiện cần theo dõi: `SleepTrackingService.stopSleepTracking` xóa active session khỏi SharedPreferences trước khi `SleepProvider.stopTracking` hoàn tất ghi repository. Nếu repository ném lỗi, Provider đã hủy timer và xóa active state, trong khi completed state được gán trước khi gọi repository; giao diện không thể khôi phục tracking state từ riêng UI; màn hoàn tất hiển thị cảnh báo và không khẳng định đã lưu khi service/repository ném lỗi. `startSleepTracking` cũng gán service active trước khi SharedPreferences hoàn tất. Đây là vấn đề nghiệp vụ hiện hữu; không sửa trong phạm vi giao diện.
- Kiểm tra: `dart format lib/features/sleep_tracking/presentation/sleep_tracking_screen.dart` và `flutter analyze --no-pub` không có output sau 30 giây, đã dừng theo chỉ dẫn; chưa xác minh kết quả format/analyze. Chưa chạy app hoặc kiểm tra tương tác/layout thực tế. `git diff --check` không phát hiện lỗi whitespace (Git chỉ cảnh báo LF sẽ chuyển CRLF). Bắt đầu/kết thúc/khôi phục session chưa được xác minh runtime.

## 2026-11-12 — Bảo toàn phiên ngủ khi lưu thất bại

- Đọc lại `AGENTS.md`, context, data contract, task log và kiểm tra SleepTrackingService/Provider/Repository/SessionModel cùng SleepTrackingScreen.
- Tách tạo snapshot phiên hoàn tất khỏi xóa phiên active. Provider nay lưu snapshot vào Repository trước; chỉ khi lưu thành công mới xóa active key trong SharedPreferences, dừng timer, cập nhật danh sách/thống kê và đặt `lastCompletedSession`.
- Repository ném lỗi thì exception được trả về UI; Provider và service không đổi active session, timer tiếp tục dựa trên `startTime` ban đầu và có thể thử lại. Repository bỏ qua bản ghi có cùng ID để thao tác thử lại không chèn bản sao nếu lần trước đã lưu nhưng bước xóa active bị gián đoạn. Provider cũng khóa start/stop trùng đồng thời.
- UI Sleep Tracking giữ nguyên thiết kế hiện tại; cảnh báo lỗi lưu được reset khi người dùng thử kết thúc lại. Cập nhật này không thay model, dữ liệu mẫu, API/backend, Supabase, schema hay database.
- Các kịch bản start/stop/lưu lỗi/thử lại/khởi động lại/nhấn lặp chưa thể chạy tự động trong môi trường này: `dart format` trên các file Dart đã sửa và `flutter analyze --no-pub` đều không có output trong 30 giây và đã dừng theo yêu cầu; chưa có kết quả analyzer hoặc test runtime. `git diff --check` chạy riêng sau cập nhật log.

## 2026-11-12 — Ổn định snapshot khi thử lưu lại phiên ngủ

- Đọc lại hướng dẫn/context/data contract/task log và kiểm tra luồng Service → Repository → Provider → UI.
- `SleepTrackingService` nay tạo snapshot hoàn tất một lần, lưu JSON ở SharedPreferences key riêng và tái sử dụng đúng snapshot trong các lần retry. `init()` phục hồi snapshot đang chờ sau khởi động lại. Snapshot và active key chỉ được xóa sau khi Repository xác nhận lưu.
- Nếu xóa một trong các key sau khi lưu thành công bị lỗi, Service giữ cache và key còn lại để lần sau tiếp tục. Provider phục hồi pending snapshot, đóng băng thời lượng hiển thị theo snapshot, giữ active state khi repository/finalize lỗi và chỉ chuyển sang completed khi cleanup hoàn tất.
- `SleepRepository.addSession` nay upsert theo ID: retry không tạo bản ghi thứ hai, đồng thời giá trị đã lưu được đồng bộ chính xác với snapshot mà Provider hoàn tất. Điều này cũng xử lý bản ghi cùng ID có snapshot cũ từ phiên bản trước.
- File sửa: `lib/core/constants/app_constants.dart`, `lib/services/sleep_tracking_service.dart`, `lib/providers/sleep_provider.dart`, `lib/repositories/sleep_repository.dart`, `docs/TASK_LOG.md`. Không đổi model, UI trong nhiệm vụ này, dependencies, backend/API, Supabase, schema/database.
- Các kịch bản lưu lỗi/thử lại, lỗi cleanup, phục hồi sau restart, cùng snapshot Provider/Repository và nhấn lặp chưa được chạy runtime. `dart format` và `flutter analyze --no-pub` không phản hồi sau 30 giây và đã dừng; kết quả chưa xác minh. `git diff --check` hoàn tất sau cập nhật log.

### Rà soát trước khi push — snapshot upsert và phục hồi trạng thái hoàn tất

- Xác minh `SleepRepository.addSession` thay thế giá trị có cùng ID bằng chính object snapshot được truyền vào; Provider cũng gán cùng snapshot làm `lastCompletedSession`, nên dữ liệu hai phía khớp hoàn toàn trong implementation hiện tại.
- Phát hiện và sửa trường hợp active key đã xóa nhưng pending key còn lại: thêm trường `repository_saved` trong JSON snapshot trên cùng SharedPreferences key, được ghi sau khi Repository lưu. Startup nhận diện pending đã xác nhận, upsert lại cùng snapshot để khôi phục history của repository process-local, hiển thị completed thay vì tracking, rồi thử cleanup. Trạng thái xác nhận và snapshot được xóa cùng một key; nếu cleanup key lỗi, startup vẫn biết snapshot đã được Repository xác nhận.
- Nếu khôi phục/upsert Repository ở startup thất bại, pending giữ trạng thái có thể thử lại thay vì báo hoàn tất. Không đổi API/schema/database.

## 2026-11-12 — Đợt 6B: cleanup pending snapshot trước phiên mới

- Xác nhận checkout bắt đầu tại `63fdbcc`; đọc AGENTS và rà soát Service/Provider/UI/task log hiện tại.
- `SleepProvider.startTracking` nay nạp lại persisted state trước khi quyết định. Pending chưa được Repository xác nhận sẽ báo rõ và không bị xóa; pending đã xác nhận phải cleanup active/pending thành công trước khi gọi Service. Lỗi cleanup được trả cho UI và không tạo/ghi đè phiên mới. `lastCompletedSession` chỉ được xóa sau khi active mới đã được ghi thành công.
- `SleepTrackingService.startSleepTracking` kiểm tra pending/active và khóa bắt đầu đồng thời; chỉ gán `_activeSession` sau khi `SharedPreferences.setString` trả `true`, nếu không thì ném lỗi. Provider chỉ cập nhật active/timer sau khi Service xác nhận ghi.
- UI hiển thị thông điệp cụ thể của Provider cho phiên trước chưa lưu hoặc cleanup chưa hoàn tất; trạng thái hoàn tất giữ nguyên khi bắt đầu thất bại.
- Không đổi model, mock data, route, dependency, backend/API, Supabase/schema/database.
- `git diff --check` chạy sau thay đổi. `dart format` và `flutter analyze --no-pub` được thử nhưng không phản hồi sau 30 giây, đã dừng; chưa xác minh analyzer hoặc runtime. Các kịch bản lỗi SharedPreferences/cleanup cần kiểm tra trên môi trường hỗ trợ.
- Trước cleanup pending đã xác nhận trong `startTracking`, Provider upsert snapshot cũ vào Repository trước để bảo toàn lịch sử process-local; lỗi rehydrate cũng chặn phiên mới và giữ snapshot.
