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
