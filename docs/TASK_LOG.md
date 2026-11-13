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

## 2026-11-13 — Đợt 6B follow-up: báo lỗi bắt đầu và chặn ghi đè phiên phục hồi

- Đối chiếu code tại `63fdbcc` như yêu cầu và phát hiện checkout hiện tại đã tiến tới `31d6b56` (`origin/main`) với phần lớn triển khai Đợt 6B. Không reset/checkout lùi để tránh mất lịch sử.
- Giữ luồng cleanup pending đã xác nhận, cờ repository_saved, xác nhận lưu active SharedPreferences và preservation của `lastCompletedSession` từ checkout hiện tại.
- Bổ sung để Provider đọc pending trước khi phân loại trạng thái active; pending chưa lưu được báo đúng là cần retry, pending đã lưu sẽ rehydrate/cleanup trước phiên mới. Bỏ guard UI phụ thuộc `provider.isTracking` có thể return im lặng; lỗi domain từ Provider được hiển thị qua snackbar hiện có.
- Service tự reload persisted state bên trong `startSleepTracking` trước khi ghi, từ chối active/pending tồn tại và chỉ gán active trong memory sau khi `setString` trả true. Do đó lời gọi trực tiếp hoặc state chưa init cũng không ghi đè key có thể phục hồi.
- File sửa: `lib/services/sleep_tracking_service.dart`, `lib/providers/sleep_provider.dart`, `lib/features/sleep_tracking/presentation/sleep_tracking_screen.dart`, `docs/TASK_LOG.md`. Không đổi repository/model/mock/routes/dependencies/backend/API/Supabase/schema/database.
- `dart format lib/services/sleep_tracking_service.dart lib/providers/sleep_provider.dart lib/features/sleep_tracking/presentation/sleep_tracking_screen.dart` không có output sau 30 giây và đã dừng; chưa xác minh format. `flutter analyze --no-pub` cũng không có output sau 30 giây và đã dừng; chưa xác minh analyzer/runtime. `git diff --check` hoàn tất, không có lỗi whitespace (Git cảnh báo LF sẽ chuyển CRLF).

## 2026-11-13 — Đợt 6B: khôi phục màn hoàn tất khi cleanup pending lỗi

- Đọc hướng dẫn và đối chiếu code tại `31d6b56` với checkout hiện tại `1d42b93`. UI hiện đã chỉ khóa bắt đầu lặp bằng `_isStarting`/`_isStopping`, chuyển lỗi Provider sang snackbar và chỉ chuyển tracking khi `startTracking()` hoàn tất; không còn guard im lặng theo `provider.isTracking`.
- Trong `SleepProvider.startTracking`, sau khi Repository upsert pending đã xác nhận, nếu cleanup active/pending ném lỗi thì gán lại `_lastCompletedSession = pending` và notify listeners trước khi trả lỗi. Nhờ vậy completion view được khôi phục cả khi người dùng đã đóng nó trước đó; snapshot không được tạo lại hoặc chỉnh sửa.
- Giữ thứ tự phân biệt pending chưa lưu / pending đã lưu / active thực, repository_saved, upsert ID, retry/restart recovery, khóa thao tác và xác nhận SharedPreferences trước khi Provider chuyển sang tracking. Không sửa Service/UI trong lượt này.
- `dart format lib/providers/sleep_provider.dart` và `flutter analyze --no-pub` không có output sau 30 giây; đã dừng theo yêu cầu, chưa xác minh format/analyzer. Không chạy được kiểm thử runtime các tình huống cleanup/SharedPreferences. `git diff --check` hoàn tất, không phát hiện lỗi whitespace (Git có cảnh báo chuẩn hóa LF/CRLF).

## 2026-11-13 — Đợt 6C: phân biệt active và pending recovery
- Đọc AGENTS/context/data contract/task log và rà soát Service → Repository → Provider → SleepTrackingScreen.
- Provider nay giữ `activeSession` chỉ cho phiên thực sự đang chạy; pending completed được giữ riêng, dù active backup key còn tồn tại. Khi Repository rehydrate pending đã đánh dấu lưu thất bại, Provider không gán snapshot kết thúc vào active, giữ nguyên snapshot/thời điểm và đánh dấu recovery failure. Start mới tiếp tục bị chặn cho đến khi pending được retry/cleanup.
- Thêm trạng thái pending UI với thông báo tùy pending chưa lưu hay đã lưu nhưng chưa phục hồi; nút retry gọi luồng upsert/mark/cleanup hiện có. Khi cleanup trong start thất bại, completed result được giữ; Provider chỉ chuyển sang active sau khi Service xác nhận lưu key mới.
- Retry stop hoạt động cả khi Provider đã phục hồi pending; dùng cùng snapshot ID. Khi hoàn tất, Provider tạo list mới thay vì mutate list unmodifiable từ Repository. Giữ upsert và khóa đồng thời.
- Thêm `test/sleep_tracking_state_test.dart`: pending retry giữ nguyên fields, active restore, pending đã lưu rehydrate trước phiên mới, upsert thay thế cùng ID, và khóa start/stop đồng thời. Repository là singleton in-memory và các thành phần hiện chưa có injection point để ép lỗi Repository/SharedPreferences; các lỗi ghi/cleanup và lỗi upsert phục hồi không thể mô phỏng trực tiếp qua test hiện tại.
- `dart format` (provider, screen, test), `flutter analyze --no-pub`, và `flutter test test/sleep_tracking_state_test.dart` đều không xuất output sau 30 giây; đã dừng theo yêu cầu. Chưa xác minh format/analyzer và các test chưa chạy đến kết quả. `git diff --check` được chạy sau ghi log; chưa phát hiện lỗi whitespace (Git cảnh báo CRLF normalization).
- Không thay Service, Repository, model, route, mock data, dependencies, backend/API, Supabase/schema/database. Không commit/push.

## 2026-11-13 — Đợt 6D: kiểm thử và xác nhận luồng Sleep Tracking

- Bổ sung injection seams tối thiểu: `SleepTrackingService.forTesting` nhận storage interface, `SleepProvider` nhận repository interface và service tùy chọn; mặc định ứng dụng vẫn dùng singleton hiện tại. `SleepRepository.forTesting()` tạo repository in-memory độc lập để test upsert mà không sửa dữ liệu demo dùng chung.
- Thay test phụ thuộc singleton/SharedPreferences dùng chung bằng fake storage/repository độc lập, có thể ép lỗi ghi marker, lỗi xóa active/pending, lỗi Repository và lỗi khôi phục. Bộ test bao phủ start/stop thường, save thất bại và retry cùng snapshot, marker save thất bại qua restart, hai dạng cleanup thất bại qua restart, recovery Repository thất bại và UI retry, ghi active thất bại, khóa start/stop đồng thời, và upsert snapshot chính xác theo ID.
- Thêm kiểm tra pending đã lưu vẫn chặn tạo phiên mới khi cleanup chưa hoàn tất; trạng thái active của UI vẫn null trong recovery lỗi. Không sửa giao diện, model, route, dependencies, backend/API, Supabase, schema hoặc database; không kết nối dữ liệu thật.
- Xác minh lệnh: `git diff --check` không phát hiện lỗi whitespace. `dart format lib/services/sleep_tracking_service.dart lib/repositories/sleep_repository.dart lib/providers/sleep_provider.dart test/sleep_tracking_state_test.dart`, `flutter analyze --no-pub` và `flutter test test/sleep_tracking_state_test.dart` đều không xuất đầu ra sau 60 giây; đã dừng các phiên lệnh này. Danh sách tiến trình chỉ cho thấy các tiến trình Dart có từ 2026-11-12; truy vấn chi tiết tiến trình bị hệ thống từ chối quyền. Vì test mục tiêu chưa cho kết quả nên không chạy toàn bộ `flutter test`. Format, analyze và runtime test chưa được xác minh; không tuyên bố test thành công.
- Không commit hoặc push.

## 2026-11-13 — Đợt 6E: điều tra công cụ và rà soát test Sleep Tracking

- Rà soát diff Đợt 6D và `test/sleep_tracking_state_test.dart`: có 9 test; mỗi test tạo storage/repository/service/provider riêng (test upsert dùng `SleepRepository.forTesting()`), không dùng singleton app hoặc SharedPreferences thật. Fake mô phỏng thật các lỗi write/remove và Repository throw; retry so sánh `toJson()` snapshot để giữ ID/timestamp/duration. Provider được `dispose` bằng teardown; timer periodic thuộc Provider bị hủy khi dispose. Test phục hồi giả lập restart bằng service/provider mới trên cùng fake storage. Adapter SharedPreferences thật chưa được chạy tích hợp.
- Dart SDK trực tiếp (`D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe --version`) chạy thành công trong khoảng 0,31 giây, Dart 3.13.0. `dart.bat --version` không trả output quá 60 giây; tiến trình wrapper `cmd.exe` dùng CPU liên tục. Đọc `shared.bat` cho thấy vòng lặp thử khóa độc quyền `bin\cache\flutter.bat.lock`. Flutter SDK nằm ngoài vùng ghi được; Flutter tool trực tiếp báo không mở được `bin\cache\lockfile` vì Access denied. Có tiến trình cmd/Dart/Java cũ từ 2026-11-12, nhưng quyền WMI/tasklist không cho đọc command line/handle nên chưa xác định tiến trình nào giữ khóa. Kết luận có căn cứ: lệnh wrapper mắc ở khâu khóa/khởi động SDK; không đủ bằng chứng quy nguyên nhân duy nhất cho process cũ hay quyền filesystem.
- Chạy format-check bằng Dart executable trực tiếp với `dart format --output=none --set-exit-if-changed lib test`: hoàn tất trong khoảng 0,79 giây, báo 50 files examined / 43 would change, exit 1. `--output=none` không ghi định dạng vào source. Sau đó Dart telemetry báo Access denied khi cập nhật file session trong profile người dùng; không thể phân biệt exit do formatter drift với telemetry error. Format check **không pass**.
- `flutter analyze --no-pub` và `flutter test test/sleep_tracking_state_test.dart --reporter expanded` qua Flutter tool trực tiếp không chạy được: khởi tạo Android SDK thử gọi `where aapt` nhưng bị Access denied; `where.exe aapt` chạy độc lập được và báo không tìm thấy aapt. Thử tiếp với Android SDK rỗng tạm trong `%TEMP%` để bỏ dò `where` vẫn gặp Access denied khi Flutter tool mở `bin/cache/lockfile`. `dart analyze` trực tiếp cũng dừng trước phân tích vì không được phép tạo process `dartaotruntime.exe`. Không có test nào được thực thi: 0 passed / 0 failed / 9 chưa chạy; không chạy toàn bộ `flutter test` vì test mục tiêu chưa thành công.
- Nguyên nhân treo của wrapper được khoanh vùng đến khâu lấy khóa/khởi động Flutter SDK với quyền hiện tại; quyền đọc process handles và ghi cache SDK bị giới hạn. Chưa xác minh được ai giữ lock, analyzer, runtime test, tương tác plugin SharedPreferences thật, hoặc format sạch. Không sửa mã nguồn, dependencies, backend/API, Supabase, schema/database; chỉ cập nhật tài liệu. Android SDK giả trong `%TEMP%` chỉ phục vụ chẩn đoán; không có thay đổi SDK hoặc dữ liệu ứng dụng. Không commit/push.

## 2026-11-13 ? ??t 6F: s?a v? x?c minh 3 test Sleep Tracking

- Ph?n t?ch nguy?n nh?n hai test cleanup: `failNextRemove` l? injection m?t l?n v? ?? b? ti?u th? trong l?n `stopTracking()` ??u ti?n. Sau restart, `startTracking()` retry cleanup v?i storage kh?ng c?n l?i; Provider ?? cleanup pending c? v? b?t ??u phi?n m?i ??ng logic. V? v?y expectation exception tr??c ?? kh?ng kh?p tr?ng th?i test t?o ra, kh?ng ph?i l?i Provider. C?p nh?t test ?? b?m th?m m?t l?i remove ngay tr??c l?n `startTracking()` c?n ki?m tra; x?c nh?n exception, active v?n null, pending snapshot kh?ng ??i, v? retry `stopTracking()` ho?n t?t c?ng ID/d? li?u, ch? c? m?t session theo ID.
- Test UI recovery tr??c ?? tap n?t khi `_PendingView` c?n ngo?i hit-test do n?i dung cu?n. `_PendingView` d?ng `SingleChildScrollView`; test nay g?i `ensureVisible` tr??c khi tap. Sau retry ki?m tra pending ?? cleanup, recovery flag false, kh?ng active session, `lastCompletedSession` v? service gi? ??ng snapshot ?? ho?n t?t, Repository ch? c? m?t row theo ID.
- File s?a trong ??t 6F: `test/sleep_tracking_state_test.dart`, `docs/TASK_LOG.md`. Kh?ng c?n s?a Service, Repository, Provider ho?c UI; kh?ng thay ??i backend/API/Supabase/schema/database.
- `dart format test/sleep_tracking_state_test.dart`: th?nh c?ng, 1 file formatted. `flutter analyze --no-pub`: ho?n t?t; 0 errors, 3 warnings, 94 infos (97 diagnostics), exit code 1 do diagnostics c?n l?i. Ba warning l? unnecessary non-null assertions trong `lib/features/home/presentation/home_screen.dart`; kh?ng thu?c ph?m vi ??t n?y. Infos ch? y?u g?m deprecated `withOpacity`, m?t import kh?ng c?n thi?t v? lint import t??ng ??i trong test.
- `flutter test test/sleep_tracking_state_test.dart --reporter expanded`: 9/9 passed. `flutter test --reporter expanded`: 10/10 passed, g?m 9 test Sleep Tracking v? smoke test ?ng d?ng. C?c l?nh Flutter c?n quy?n truy c?p cache SDK ngo?i workspace; khi ch?y trong sandbox th??ng wrapper k?t t?i b??c l?y kh?a, sau ?? ch?y v?i quy?n SDK cache ph? h?p v? nh?n k?t qu? ho?n ch?nh. Kh?ng c?n test ch?a x?c minh trong c?c l?nh tr?n.
- `git diff --check` ho?n t?t, kh?ng ph?t hi?n l?i whitespace. Kh?ng commit/push.
## 2026-11-13 — Đợt 7B: sửa responsive và bố cục

- Rà soát Forgot Password, Profile, MainShell, History, Login, Register và Dream List theo cấu trúc checkout hiện tại; giữ nguyên Provider, Repository, GoRouter, model, dữ liệu mock và hành vi nghiệp vụ.
- Forgot Password dùng vùng cuộn dọc và giới hạn chiều rộng để nội dung vẫn truy cập được khi bàn phím mở/màn hình thấp. Profile chuyển hàng mục tiêu ngủ sang `Wrap`, cho phép nhãn và giá trị xuống dòng. MainShell chia đều không gian cho 5 mục, giảm padding trên màn hẹp và co nhãn khi cần; giữ nguyên index/route.
- History cho phép cuộn ngang hàng bộ lọc trong khi vùng tab/lịch sử tiếp tục cuộn dọc. Login, Register giới hạn form 520px; Dream List giới hạn nội dung 760px trên màn hình lớn, giữ padding mobile và scroll/refresh.
- File source thay đổi: `lib/features/authentication/presentation/forgot_password_screen.dart`, `lib/features/profile/presentation/profile_screen.dart`, `lib/shared/widgets/main_shell.dart`, `lib/features/history/presentation/history_screen.dart`, `lib/features/authentication/presentation/login_screen.dart`, `lib/features/authentication/presentation/register_screen.dart`, `lib/features/dream_diary/presentation/dream_list_screen.dart`.
- `dart format` đã định dạng cả 7 file. Kiểm tra lại `dart format --output=none --set-exit-if-changed` báo 7 file, 0 file cần thay đổi; tiến trình sau đó trả exit 1 do Dart không được phép cập nhật `C:\Users\Dien\AppData\Roaming\.dart-tool\dart-flutter-telemetry-session.json`. Vì lỗi telemetry quyền truy cập, mã thoát formatter không sạch dù formatter báo không còn khác biệt.
- `flutter analyze --no-pub` chạy hơn 40 giây nhưng không phát output, sau đó được dừng; không có kết quả analyzer. `flutter test --reporter expanded` cũng không phát output sau khoảng 50 giây và được dừng; 0 test được xác nhận chạy, không thể báo pass/fail. Trong lúc analyzer chạy, tiến trình `cmd` có CPU tăng; nguyên nhân cụ thể của việc Flutter chưa khởi chạy phân tích/test chưa được xác minh.
- Chưa có widget test theo các kích thước 320/375/768/1024px và chưa chạy ứng dụng trên thiết bị/emulator; không tuyên bố đã kiểm tra trực quan. `git diff --check` được chạy sau cập nhật log.
- Không thay đổi backend, API, Supabase, schema/database; không đọc `.env`; không commit/push.

## 2026-11-13 — Đợt 7B.1: xác minh responsive sau chỉnh sửa

- Working tree trước khi kiểm tra có các thay đổi Đợt 7B chưa commit. Dart executable trực tiếp trả `Dart SDK version: 3.13.0 (stable)`; `flutter --version` không trả output sau khoảng 20 giây và được dừng. Thử `flutter --verbose --version` cũng không có output sau khoảng 20 giây.
- Kiểm tra process thấy các process `cmd`/`dart` cũ bắt đầu từ 2026-11-12 và một process `cmd` từ lượt hiện tại có CPU tăng; truy vấn process command line không trả dữ liệu nên không xác định được nguồn gốc/handle lock. Trong `D:\Flutter\flutter\bin\cache` có `flutter.bat.lock` và `lockfile` với LastWriteTime 2026-11-13 01:29. Không xóa lock và không kết thúc process nền/không xác định.
- `dart format --output=none --set-exit-if-changed` trên 7 file Đợt 7B báo `7 files (0 changed)`; exit code 1 phát sinh sau đó khi Dart telemetry không có quyền cập nhật `C:\Users\Dien\AppData\Roaming\.dart-tool\dart-flutter-telemetry-session.json`. Kết luận formatter không thấy file cần format, nhưng lệnh không có exit code sạch.
- `flutter analyze --no-pub` không xuất output sau khoảng 40 giây; dừng lệnh do lượt này khởi chạy. `flutter test --reporter expanded` không xuất output sau khoảng 50 giây; dừng lệnh do lượt này khởi chạy. Không có kết quả analyzer; 0 test được xác nhận chạy (pass 0 / fail 0 / chưa chạy 10). Flutter CLI verbose cũng không tạo log trước khi dừng; chưa xác định chắc chắn nguyên nhân wrapper bị chặn dù có lock cũ và process CPU tăng.
- Không chạy được widget test ở kích thước 320, 375, 768 hoặc 1024px; chưa kiểm tra cuộn/overflow bằng runtime hay kiểm tra trực quan trên thiết bị. Không có mã nguồn UI nào được sửa trong lượt xác minh này.
- `git diff --check` hoàn tất, không phát hiện whitespace error. Chưa xác minh analyzer, test/runtime và layout trên các kích thước mục tiêu. Không đọc `.env`, không chạy đồng thời lệnh Flutter, không xóa lock, không sửa backend/API/Supabase/schema/database, không commit/push.

## 2026-11-13 — Đợt 7B.2: chẩn đoán Flutter CLI

- Đường dẫn được xác nhận: `D:\Flutter\flutter\bin\flutter.bat`; Flutter tool snapshot `D:\Flutter\flutter\bin\cache\flutter_tools.snapshot`; Dart đi kèm Flutter `D:\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe`. PATH có `C:\dart-sdk\bin` (không có `dart.exe` tại đó), `D:\Flutter\flutter\bin` và một entry `D:\Flutter\bin` không tồn tại. `FLUTTER_ROOT` và `DART_SDK` không được đặt trong môi trường PowerShell ban đầu. Dart 3.13.0 chạy trực tiếp.
- Process hiện có: cmd PID 3540 (bắt đầu 2026-11-13 01:22, CPU tích lũy cao); cmd PID 18384/22812 và Dart PID 10736/22748/23088/23428 bắt đầu khoảng 01:04. Dart PID 10736 dùng khoảng 277 MiB working set, các Dart còn lại khoảng 10–32 MiB. Không có process `flutter.exe`. CIM không trả command line/quan hệ cha-con, nên không gán được process cũ cho Flutter hoặc xác định chủ sở hữu lock.
- ACL của `D:\Flutter\flutter\bin`, `bin\cache` và `bin\cache\lockfile` liệt kê Modify cho Authenticated Users; đọc thư mục và mở lockfile chỉ đọc đều thành công. Mở thử lockfile và `flutter.bat.lock` bằng FileShare.None cũng thành công tại thời điểm kiểm tra, nên không chứng minh được đang có handle độc quyền giữ lock. Không ghi file thử nghiệm, xóa lock hoặc sửa SDK.
- `where.exe git` và `where.exe PowerShell` chạy được; `pwsh` không có trong PATH. `where.exe aapt` chạy được độc lập nhưng trả code 1 (không tìm thấy aapt). Không tìm thấy Flutter log file trong Temp, LocalAppData, Roaming hoặc cache theo tên log.
- Mã bootstrap `bin\internal\shared.bat` có vòng `:acquire_lock` (dòng 52–56) lặp lại nếu subroutine trả lỗi. Subroutine gọi `update_engine_version.ps1`, script này ghi `bin\cache\engine.stamp` và `engine.realm`. Vì wrapper không phát output và có cmd CPU tăng, bootstrap loop là giả thuyết có căn cứ; chưa chạy script ghi cache nên chưa xác nhận lỗi write là nguyên nhân vòng lặp. Lock file tồn tại và timestamp cũ tự nó không chứng minh có process giữ lock.
- Gọi trực tiếp Dart + `flutter_tools.snapshot --version --verbose` để bỏ qua batch bootstrap trả exit 1 và stack trace: `CreateFile failed 5 (Access is denied)` nhiều lần, sau đó `Flutter failed to run "where aapt"`; stack đi qua `ErrorHandlingProcessManager.runSync` → `WindowsUtils._which` → `AndroidSdk.locateAndroidSdk`. Đây là nguyên nhân đã xác nhận khiến Flutter tool không thể khởi tạo trong môi trường hiện tại: tiến trình Dart của tool bị từ chối khi khởi chạy `where aapt`, dù `where.exe aapt` chạy độc lập từ PowerShell. Không có output analyze/test nên không xác minh analyzer hay số test.
- Không sửa source app hoặc SDK, không thay environment bền vững, không dừng process nền, không xóa lock, không đọc secret. Đề xuất tối thiểu: chạy xác minh ngoài sandbox/quyền thực thi process đầy đủ hoặc nhờ quản trị môi trường cho phép Flutter tool tạo tiến trình con; sau đó chạy lại Flutter command tuần tự. Trước khi thay quyền/di chuyển SDK hoặc dừng PID 3540 cần xác minh chủ process/handle và xin duyệt riêng.
- `git diff --check` cần chạy sau lần ghi log này. Chưa có widget/runtime responsive test; không commit/push.

## 2026-11-13 — Đợt 7B.3: analyzer warnings và responsive widget tests

- Bỏ đúng ba unnecessary null assertion trong `lib/features/home/presentation/home_screen.dart` ở các truy cập `latestSession` đã được flow promotion bảo đảm. Không thay đổi logic hiển thị.
- Thêm `test/responsive_layout_test.dart` với 7 widget tests: Forgot Password (320×420, inset bàn phím mô phỏng 260px, text scale 1.3, cuộn tới nút và submit validation); Profile (320/375, text scale 1.5); MainShell, History, Login, Register và Dream List tại 320/375/768/1024 (text scale 1.2–1.3). Test kiểm tra ngoại lệ layout, các trường/nội dung, thao tác tab/filter và giới hạn form/list trên màn rộng. Đây là test code, chưa phải kết quả runtime.
- `dart format --output=none --set-exit-if-changed` trên 9 Dart files báo `9 files (0 changed)` nhưng exit 1 do Dart không được phép cập nhật file telemetry tại `%APPDATA%\.dart-tool`; format không báo file nào cần đổi nhưng exit status không sạch.
- `flutter analyze --no-pub` qua `flutter.bat` không có output sau khoảng 60 giây. Gọi trực tiếp Flutter tool snapshot với SDK discovery tạm trong `%TEMP%` trả: `Flutter failed to open a file at "D:\Flutter\flutter\bin\cache\lockfile"` (Access denied). Analyzer không hoàn thành nên số warnings/infos còn lại chưa xác minh; ba null assertion đã được bỏ trong source nhưng không báo analyzer là đã sạch.
- Widget test mới và full `flutter test --reporter expanded` qua Flutter tool snapshot đều dừng ngay với cùng lỗi không mở được SDK `bin/cache/lockfile`; không có test được xác nhận chạy, 0 pass / 0 fail. Do đó chưa xác minh được test mới biên dịch hoặc phát hiện overflow thực tế.
- Kích thước và text scale đã được khai báo trong widget tests như trên, nhưng chưa được Flutter pump/runtime kiểm tra. Chưa tuyên bố kiểm tra trực quan thiết bị.
- File app sửa: `lib/features/home/presentation/home_screen.dart`; test thêm: `test/responsive_layout_test.dart`; `TASK_LOG.md` cập nhật. Không sửa Provider/Repository/GoRouter/model/mock/backend/API/Supabase/schema/database; không đọc `.env`; không commit/push. `git diff --check` cần chạy sau cập nhật log.

## 2026-11-13 — Đợt 7B.3 follow-up: sửa lỗi tìm thấy từ responsive tests

- Responsive tests ban đầu phát hiện: Forgot Password nút submit tràn 4.8px; Register nút chính tràn 26px; Dream List tràn 176px ở 320px do nội dung label của `AppButton` không co theo hàng; Login footer và Register footer tràn ở màn hẹp; Profile phát cảnh báo ListTile ink/background nằm dưới `DecoratedBox`.
- Sửa `AppButton` để label có thể wrap trong phần `Flexible`, giữ nguyên nhãn và kiểu nút; Login/Register chuyển hàng liên kết cuối trang sang `Wrap`; Profile đặt nội dung có ListTile trong Material để lớp nền/ink được vẽ đúng. Không đổi luồng nghiệp vụ, Provider, Repository, route, model hay dữ liệu mock.
- Final analyzer `flutter analyze --no-pub` đã chạy: **0 warnings, 95 infos**, exit 1 do còn diagnostics info. Ba warning `unnecessary_non_null_assertion` đã hết. Không xử lý hàng loạt infos; phần tăng từ 94 lên 95 so với baseline có thể đến từ test mới và chưa được quy loại từng info.
- Format-check trên 10 Dart files báo `10 files (0 changed)`; Dart sau đó trả exit 1 vì không được phép cập nhật file telemetry trong `%APPDATA%\.dart-tool`. Không có file cần format theo kết quả formatter, nhưng exit code không sạch.
- `flutter test test/responsive_layout_test.dart --reporter expanded`: **7 testWidgets passed**. Bao phủ Forgot Password 320×420 với inset bàn phím mô phỏng/text scale 1.3; Profile 320/375 với text scale 1.5; MainShell, History, Login, Register, Dream List ở 320/375/768/1024 với text scale 1.2–1.3. Các test xác nhận không còn exception/overflow, tab/filter thao tác được, các form/list được giới hạn chiều rộng.
- `flutter test --reporter expanded`: **17/17 passed** (7 responsive, 9 Sleep Tracking, 1 app smoke test). `git diff --check` cần chạy sau ghi log.
- Analyzer/tests chỉ chạy được sau khi chấp thuận quyền sử dụng cache Flutter SDK ngoài workspace; lần chạy trong sandbox bị từ chối `bin/cache/lockfile`. Thư mục SDK discovery giả trong `%TEMP%` đã được xóa sau chẩn đoán; không cài/thay Flutter SDK.
- Chưa chạy ứng dụng trên thiết bị/emulator; các kích thước được xác minh qua widget tests, không phải kiểm tra trực quan phần cứng. Không sửa backend/API/Supabase/schema/database; không đọc `.env`; không commit/push.

## 2026-11-13 - Dot 7C.1: Home, Analytics, History loading/error states

- Cause: DreamProvider exposed only a loading flag and error text without a completed/successful-load marker. SleepProvider used one loading flag for session and statistics requests and swallowed repository errors; screens treated empty in-memory lists/default statistics as a successful empty result. Analytics refresh also called statistics without passing or retaining dream data, so emotion distribution could be cleared.
- Changes: added injectable DreamDataRepository and explicit DreamProvider load/success state; added independent SleepProvider session/statistics loading, loaded, successful and error state while preserving successful cached values on request failure and retaining the last loaded dream list for statistics refresh. Home now renders loading/error/retry separately for dream, sleep session and statistics sources; Analytics distinguishes loading/error/empty and refreshes with retained dreams; History loads and displays each source independently with per-source retry. Added widget coverage with isolated fake repositories.
- Tests: new `test/data_state_test.dart` has 6 passing widget tests covering Home loading/empty/error and source retries, Analytics error/no fake chart/retry and emotion retention across refresh, and History independent source failure/retry. Full `flutter test --reporter expanded`: 23/23 passed (including responsive and sleep-tracking suites).
- Checks: `dart format --output=none --set-exit-if-changed` on all 7 changed Dart files: passed, 0 changed. `flutter analyze --no-pub`: analyzer completed with 98 issues, all informational (0 warnings, 0 errors); exit code 1 because infos remain. `git diff --check` result recorded after this entry.
- Scope: no UI redesign, model/schema/database/backend/API changes, Supabase calls, secrets access, commit or push. Existing mock repositories remain the source of screen data.
- Environment note: first sandboxed `dart format` invocation produced no output for over 30 seconds; only that task-owned process was stopped. Retrying formatter with the installed SDK's required host permission completed successfully. Flutter analyzer and tests also required SDK-cache access and completed with the elevated tool permission.

## 2026-11-13 - Dot 7C.2: Dream Detail/Edit record loading by ID

- Cause: Detail and Edit resolved `dreamId` only through synchronous `DreamProvider.getDreamById()`, which searched the in-memory list. A valid record was therefore rendered as missing when the list had not loaded or did not contain that ID. Edit also marked its one-time initialization complete when no record was available, preventing later recovery.
- Changes: DreamProvider now exposes per-ID loading status, error/not-found distinction, retry and deduplicated asynchronous lookup through the existing repository method. Successful ID results are cached separately from the list to avoid duplicate list rows; updates/deletes synchronize this cache. Detail now shows loading, retryable error, and not-found states. Edit waits for a resolved record before creating controllers, retries failures, initializes once per ID, resets/reloads on ID changes and retains existing user edits across ordinary rebuilds. Update continues to use `original.copyWith(...)`, preserving ID, userId and createdAt.
- Tests: added `test/dream_record_state_test.dart` with 11 passing tests: Detail loading/success/not-found/error-retry; Edit loading/error-retry/not-found; user text retention; metadata preservation after save; ID change; no repeated query on rebuild. Focused test file: 11/11 passed. Full `flutter test --reporter expanded`: 34/34 passed, including existing Home/Analytics/History, responsive and Sleep Tracking tests.
- Checks: formatter check on the four changed Dart files passed (0 changed). `flutter analyze --no-pub` completed with 98 info diagnostics, 0 warnings and 0 errors; exit code 1 due remaining infos. `git diff --check` result recorded after this entry.
- Scope: no model, route, backend/API, Supabase, schema/database or mock data changes; no secrets access; no commit or push.

## 2026-11-13 - Dot 7C.3: Authentication UI and user feedback

- Changes: Login starts with blank email/password, retains password visibility toggle, validates input, shows submit loading/error and guards repeat submission. Register validates name/email/password/confirmation, has password visibility controls, loading/error and duplicate-submit guard. A successful mock registration no longer creates an authenticated local session or routes to Home; its completion view explicitly states no real account or verification email was created. Forgot Password validates email, shows loading, prevents duplicate submit and distinguishes request failure from mock acceptance; its success view explicitly states no email was sent. Responsive scrolling is retained.
- Mock limitations: `ApiService.login/register` still return local mock responses; login accepts any valid-form credentials. Register response is not persisted as an authenticated session. `AuthService.forgotPassword` only simulates 700ms latency and sends no email. No Supabase Auth was integrated.
- Tests: added `test/auth_ui_test.dart` with 13 widget tests for empty login, validation, password visibility, loading/deduplication across all three forms, failed login/register staying off Home, registration not treated as verified, forgot-password validation/success/failure disclosure, and 320x420 keyboard-inset layouts. Focused auth test: 13/13 passed. Full `flutter test --reporter expanded`: 47/47 passed.
- Checks: formatter check on 7 changed Dart files passed (0 changed). `flutter analyze --no-pub` completed with 101 info diagnostics, 0 warnings, 0 errors; exit code 1 due infos. `git diff --check` result recorded after this entry.
- Scope: no route, model, API contract, backend, database, schema, RLS or Supabase changes; no package added; no `.env` access; no commit or push.

## 2026-11-13 - Đợt 7D: Kiểm toán trước tích hợp Supabase

- Audit read-only toàn bộ luồng Flutter/auth/dream/sleep/analytics/profile, Express routes/middleware/Supabase client, schema SQL và tài liệu contract. Không mở `.env` hoặc `server/.env`; chỉ kiểm tra metadata file tồn tại/tracked và tên biến trong `.env.example`. Không gọi Supabase, không chạy server/migration, không sửa source/SQL/database.
- Findings quan trọng được ghi trong `docs/PRE_INTEGRATION_AUDIT.md`: Flutter hiện dùng fixtures/in-memory, chưa gọi REST; API client cấu hình localhost:5000 trong khi Express mặc định 3000 và không gắn bearer; auth mock lưu token SharedPreferences, thiếu refresh/route guard/server logout; `pubspec.yaml` liệt kê `.env` làm asset và `.env` hiện tồn tại (untracked); Dream/Sleep model, API route và schema legacy lệch UUID/field/type so với contract; endpoint forgot/reset chưa có. Backend dùng verified `req.user.id` và owner filter; RLS owner policies bật. Report chia P0/P1/P2 và roadmap.
- `flutter --version`: Flutter 3.47.0 stable, Dart 3.13.0.
- `flutter analyze --no-pub`: hoàn tất, 101 issues (0 warning, 0 error, 101 info), exit 1 do còn analyzer infos.
- `flutter test --reporter expanded`: 47/47 passed, exit 0.
- `git diff --check`: PASS, exit 0 sau khi cập nhật tài liệu; Git chỉ cảnh báo `TASK_LOG.md` có LF sẽ được chuyển CRLF ở lần Git ghi tiếp theo.
- Chưa chạy backend/Node test, không có xác minh kết nối Supabase, không chạy trên thiết bị thật/emulator và không thực hiện kiểm thử bảo mật xâm nhập. Chỉ `docs/PRE_INTEGRATION_AUDIT.md` và entry này được phép thay đổi trong đợt.

## 2026-11-13 — Đợt 8A.1: Bỏ env khỏi Flutter asset và thêm Auth route guard

- `pubspec.yaml`: bỏ `.env` khỏi Flutter assets; gỡ `flutter_dotenv` vì chỉ được dùng để load file không cung cấp cấu hình cho API client và Supabase init chỉ còn comment. `main.dart` không còn đọc `.env`; `.env`/`server/.env` không bị mở, xóa hay sửa. Chạy `flutter pub get --offline` để đồng bộ `pubspec.lock`; thành công, không tải package mới.
- Thêm `AuthRouteGuard`; GoRouter giờ được tạo cùng AuthProvider, lắng nghe auth changes qua `refreshListenable`. Guard chờ `AuthProvider.isInitialized`, dùng onboarding flag cho onboarding, redirect unauthenticated đến Login, chuyển authenticated khỏi auth/onboarding/splash đến Home hoặc protected deep link đích. Login/Register/Forgot Password vẫn public sau onboarding; query `from` giữ path parameters và query string khi redirect. Onboarding đưa người dùng đến login/đích đã yêu cầu; logout tự-refresh router về Login. Splash không tự quyết định auth từ `pref_is_logged_in`.
- `AuthProvider.checkAuthStatus()` nay có trạng thái khởi tạo riêng, khóa gọi restore trùng, đặt loading trong lúc restore và hoàn tất thành unauthenticated nếu restore lỗi. Đây vẫn là trạng thái local mock; không xác thực token với server.
- Thêm `test/auth_route_guard_test.dart`: 11 test cho onboarding incomplete, unauthenticated routes/deep links (Home, detail, edit, sleep), authenticated routing, logout refresh, loading/restore và register mock không thành authenticated.
- Kiểm tra cấu hình bằng `rg`: `pubspec.yaml`, `pubspec.lock`, `lib/main.dart` không còn tham chiếu `flutter_dotenv`/`dotenv`; asset list không còn `.env`.
- `dart format --output=none --set-exit-if-changed` trên 10 file Dart: PASS, 0 file cần format.
- `flutter analyze --no-pub`: exit 1 với **101 infos, 0 warnings, 0 errors**. Không khẳng định analyzer sạch; các infos tồn tại từ baseline (chủ yếu lint/deprecation) và chưa xử lý trong phạm vi.
- `flutter test test/auth_route_guard_test.dart --reporter expanded`: **11/11 passed**. `flutter test --reporter expanded`: **58/58 passed**.
- `git diff --check`: PASS, exit 0 sau khi cập nhật log; Git phát cảnh báo line ending LF→CRLF cho các file tài liệu/source sẽ chạm ở lần ghi tiếp theo.
- Hạn chế: Authentication vẫn là mock; route guard chỉ kiểm soát navigation UI, không phải biên bảo mật cho backend và không chứng minh user/session/token thật. Không kết nối Supabase, sửa backend/SQL/schema/database, thay Sleep Tracking, đọc env, commit hoặc push.

## 2026-11-13 - Đợt 8A.2: Chuẩn hóa hợp đồng dữ liệu Dream và Sleep

- Chuẩn hóa riêng ranh giới API và lưu trữ cục bộ: Dream/Sleep giữ `toJson/fromJson` hiện có cho fixture và snapshot, đồng thời có API serializer/parser nghiêm ngặt. API write không nhận ID, `user_id` hay `created_at`; Sleep write cũng không nhận `duration_minutes` hoặc cờ tracking. Dream API dùng `tags` dạng mảng chuỗi và ngày `YYYY-MM-DD`; Sleep API yêu cầu timestamp có `Z`/offset, chuẩn hóa UTC, xác thực thời gian/điểm, và duration do Express tính từ start/end.
- Backend Express được chuẩn hóa theo cùng tên trường và endpoint. UUID/path/query/body được xác thực; quyền sở hữu lọc theo `req.user.id`; tags tìm bằng PostgreSQL array containment (`contains`), `q` chỉ tìm title/content. GET trả JSON array trực tiếp. Lỗi nội bộ được trả về dạng tổng quát, không phát tán chi tiết database.
- Thêm test hợp đồng Flutter và Node dùng dữ liệu/repository giả lập cục bộ. Node dùng `node:test` built-in, không thêm dependency và không gọi Supabase. `npm test` trong `server/`: 10/10 passed. `flutter test test/model_api_contract_test.dart --reporter expanded`: 10/10 passed. Full `flutter test --reporter expanded`: 68/68 passed. Formatter `dart format --output=none --set-exit-if-changed` cho 5 file Dart: PASS, 0 changed.
- Analyzer: lần kiểm tra ở lượt này `flutter analyze --no-pub` không trả output sau 90 giây; tiến trình do lượt này khởi chạy đã được dừng bằng Ctrl+C. Không có quyền truy vấn WMI để xác định trạng thái tiến trình hệ thống. Một lần chạy trước đó trong cùng lượt đã báo `103 issues found` nhưng chưa thu được phân loại warning/error/info; vì vậy không ghi nhận analyzer sạch và chưa xác minh lại được phân loại chính xác.
- `git diff --check`: PASS, exit 0. Git chỉ hiện cảnh báo chuẩn về chuyển line ending LF sang CRLF khi ghi các file đã sửa.
- Phạm vi: cập nhật `docs/DATA_CONTRACT.md`, `docs/API_SPECIFICATION.md`, `docs/DATABASE_MIGRATION_PROPOSAL.md`; không sửa `supabase_schema.sql`, không chạy migration, không kết nối/ghi Supabase, không đọc `.env`/`server/.env`, không commit/push. Thay đổi source là Flutter model/API serialization và Express validation/routes/error handling theo phạm vi nhiệm vụ; không có thay đổi schema/database.
## 2026-11-13 - Đợt 8B.1: Rà soát schema Supabase và kế hoạch migration

- Rà soát tĩnh `supabase_schema.sql` và Express auth/CRUD. Schema trong repo vẫn legacy: dreams/sleep IDs là bigint identity; dreams dùng `tags text`, thiếu clarity/lucid/date; sleep dùng time text, quality 1–10 và note, thiếu stages/start-end timestamp. Cả hai có owner UUID FK tới `auth.users` với cascade, created_at timestamptz, index owner+created; RLS bật và có owner policies CRUD theo `auth.uid() = user_id`; không thấy unique ngoài PK. Chỉ xác nhận trong file SQL, không xác minh database Supabase đang chạy.
- Backend auth middleware xác minh Bearer token bằng `authClient.auth.getUser`; CRUD dùng `adminClient` với service-role (bypass RLS), nên ownership phụ thuộc việc server filter mọi query theo `req.user.id` và gán owner khi insert. Dreams/Sleep routes hiện có filter này. Cấu hình env example có khác tên biến giữa root/server; server example chứa giá trị cấu hình không phải placeholder thuần. Không sao chép giá trị vào log/tài liệu; cần thay bằng placeholder an toàn trước khi chia sẻ.
- Tạo `docs/SUPABASE_MIGRATION_PLAN.md` gồm bảng sai khác/risks, kế hoạch UUID mapping (không cast bigint), tags/date/sleep legacy data mapping cần xác nhận, pha backup/restore/staging/additive backfill/cutover/cleanup, RLS/ownership tests, checklist và gates/phê duyệt trước migration.
- Kiểm tra tính nhất quán: plan đối chiếu contract Đợt 8A.2 và API source; xác nhận schema tham chiếu chưa tương thích. Các điểm chưa biết (delimiter tags, nguồn dream_date, timezone sleep text, mapping quality, stages, actual data/consumers) được để mở để chủ dự án quyết định.
- `git diff --check`: PASS, exit 0 (cần chạy lại sau entry này). Chỉ cập nhật tài liệu; không sửa/chạy SQL, không kết nối Supabase, không đọc `.env`/`server/.env`, không thay đổi auth/API/source/database, không commit/push.
## 2026-11-13 - Đợt 8B.2: Làm sạch file cấu hình mẫu

- Thay giá trị trong `server/.env.example` bằng ví dụ/placeholder; giữ đúng các biến server yêu cầu (`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`) và các biến runtime (`PORT`, `NODE_ENV`, `API_BASE_URL`, `CORS_ORIGIN`). Ghi rõ service-role chỉ dùng server, không đưa vào Flutter.
- Thay `.env.example` gốc bằng ghi chú Flutter không load dotenv/CRUD Supabase trực tiếp; cấu hình Supabase thuộc server example. Chỉ kiểm tra tên biến, không ghi lại URL/key.
- Đối chiếu source: backend yêu cầu ba biến Supabase trên; trong Flutter không có tham chiếu dotenv, Supabase initialization hoặc CRUD trực tiếp. `supabase_flutter` vẫn còn trong dependency lock/manifest nhưng không thấy được gọi từ `lib/`.
- Không mở/sửa `.env` hoặc `server/.env`; không sửa source/dependency/API/SQL/database, không kết nối/migration, không commit/push.
## 2026-11-13 - Đợt 8C: Xác minh kết nối Express tới Supabase

- Đã rà soát `server/src/supabase.js`, `server/src/server.js`, health route, `server/src/middleware.js`, `server/package.json` và các query Supabase liên quan. Server tạo Auth client dùng anon key để xác minh token và admin client dùng service-role cho DB; health `GET /api/health` chạy `SELECT id FROM dreams LIMIT 1`, không ghi dữ liệu. Server startup log không in giá trị cấu hình.
- `git check-ignore -- server/.env`: PASS. File `server/.env` tồn tại: PASS. Kiểm tra cấu hình bằng script chỉ xuất trạng thái: ba tên biến bắt buộc hiện diện/không rỗng, PASS (3/3); không in giá trị.
- `npm test` trong `server/`: PASS, 10 passed / 0 failed. Test output có dòng logger `[API error] Error` từ test lỗi tổng quát; không chứa thông tin cấu hình.
- Server khởi động: PASS (`npm start`, cổng lấy từ cấu hình runtime). Supabase clients khởi tạo: PASS (server import thành công). Health check: HTTP 200, `status=ok`, `database=connected`; do health query hoàn tất thành công, kết nối database thực sự được xác minh bằng thao tác SELECT read-only giới hạn một row, không trả dữ liệu row về terminal.
- Tiến trình server do lượt này khởi chạy đã được dừng sau phép thử. Không có migration/SQL ghi, thay đổi schema/dữ liệu hoặc kết nối client Flutter.
- File cập nhật: chỉ `docs/TASK_LOG.md`. Đã kiểm tra ignore trước khi chạy; không mở/sửa `.env` hoặc `server/.env`, không in/ghi URL hay key, không commit/push. `git diff --check` được chạy sau entry này.
## Đợt 8D.1 — Tích hợp Authentication Flutter với Express/Supabase Auth (2026-11-13)

- Login/register/refresh/logout của Flutter chuyển sang `POST /auth/login`, `/auth/register`, `/auth/refresh`, `/auth/logout` trên Express. Login/register chỉ tạo authenticated state khi response có `session` hợp lệ gồm access/refresh token; register `session:null` + `confirmation_required:true` giữ unauthenticated và UI yêu cầu xác nhận email. JSON user ánh xạ `name` theo root → `user_metadata.name` → email prefix; giữ local settings của cùng user.
- Access/refresh token dùng `flutter_secure_storage` 9.2.4 (không lưu password); SharedPreferences chỉ giữ user settings/flag. Khi init xóa key mock access token cũ mà không đọc giá trị, đọc refresh token secure, gọi API refresh trước khi route guard quyết định trạng thái. Refresh thành công lưu token rotation/user/expiry; 400/401 xóa session; network/server failure giữ refresh token nhưng khởi tạo unauthenticated và UI có retry. Logout gọi backend nếu có access token nhưng luôn dọn local session khi remote call lỗi.
- `ApiClient` giữ Dio singleton, lấy bearer token qua callback để tránh vòng dependency; request mặc định cần auth, endpoint login/register/refresh đánh dấu public. Không có interceptor ghi request/response/token. API URL mặc định desktop/local là `http://localhost:3000/api`, có thể truyền `--dart-define=API_BASE_URL=...`; emulator dùng `http://10.0.2.2:3000/api`, thiết bị thật dùng LAN host URL bằng dart-define.
- Forgot Password backend chưa có endpoint: service trả `NOT_SUPPORTED`; UI nêu rõ email không được gửi. Không thay đổi backend. Dream/Sleep repositories và CRUD vẫn mock/local, chưa tích hợp API; không tích hợp Supabase Flutter trực tiếp.
- Thêm `test/auth_service_test.dart` với 11 test service/client cho login, lỗi login, dọn token mock cũ, register có/không session, restore/rotate, expired refresh, lỗi mạng giữ refresh token, logout cả khi lỗi mạng, ánh xạ UserModel, và bearer/public request qua fake Dio adapter. Cập nhật auth route/UI fakes và kiểm thử thông báo unsupported recovery. Auth-focused suite: 36/36 passed. Full `flutter test --reporter expanded`: 80/80 passed.
- `flutter pub get`: PASS, thêm `flutter_secure_storage` 9.2.4 và cập nhật lockfile. `dart format` trên 12 file Dart: PASS; check `--output=none --set-exit-if-changed`: PASS, 0 changed.
- `flutter analyze --no-pub`: hoàn tất, exit 1 vì diagnostics informational; chính xác **106 info, 0 warning, 0 error**. Không tuyên bố analyzer sạch.
- Giới hạn: test dùng fake Auth API/token storage; không có request tới Supabase hoặc tài khoản thật. Startup restore xác minh phiên bằng refresh; lỗi mạng giữ refresh credential nhưng chưa authenticated cho đến khi retry thành công. Forgot/reset email chưa hỗ trợ. Không chạy migration, không ghi database, không sửa API backend/SQL, không đọc/sửa `.env` hoặc `server/.env`, không commit/push.

## Sprint 8D.2 - Auto-refresh access token on API 401 (2026-11-13)

- ApiClient auto-refreshes only protected requests receiving 401; login/register/refresh are excluded. The original request is replayed at most once with method, URL, query, body, and Dio configuration preserved.
- AuthService shares concurrent refresh work. Tests exposed a delayed-401 race after the first refresh completed; the interceptor now retries that request using the latest access token instead of refreshing again.
- Any refresh failure, including a network failure, clears secure local tokens, sets AuthProvider to unauthenticated, and notifies GoRouter. Waiting requests finish safely with the original error.
- AuthService/ApiClient tests: 19/19 passed. Auth route guard/UI tests: 25/25 passed. Full `flutter test --reporter expanded`: 88/88 passed. Dart format check: PASS, 0 files changed. Analyzer: 105 infos, 0 warnings, 0 errors (exit 1 due to infos). `git diff --check`: PASS before this documentation update.
- No live account was used by tests; no backend/schema/database changes, env file access, commit, or push occurred.

## Supabase connection investigation (2026-11-13)

- Read-only REST schema probes completed against the configured Supabase project using `SELECT` with `limit(0)`; no user rows were fetched. `dreams` supports `id`, `user_id`, `title`, `content`, `emotion`, `tags`, and `created_at`, but lacks `clarity_score`, `is_lucid`, and `dream_date`. `sleep_records` supports `id`, `user_id`, and `duration_minutes`, but lacks `start_time`, `end_time`, `quality_score`, `deep_sleep_minutes`, `light_sleep_minutes`, `rem_sleep_minutes`, and `notes`.
- Flutter Dream/Sleep repositories remain fixture/local implementations. Existing Express CRUD routes expect the missing contract fields; CRUD must not be exposed until a schema-compatible migration/decision is reviewed.
- No migration or write query was executed. Do not read `.env` or `server/.env`; runtime loaded configured credentials without printing them.
