# Hướng dẫn cho Codex và người đóng góp

## Phạm vi hiện tại
- Giai đoạn 1 là rà soát và tài liệu hóa. Không tự ý sửa giao diện, mã ứng dụng, schema/dữ liệu Supabase hoặc đưa dữ liệu mẫu lên Supabase.
- Ưu tiên giữ cấu trúc Flutter hiện tại, thay đổi nhỏ, có phạm vi rõ ràng.
- Sau mỗi nhiệm vụ, cập nhật `docs/TASK_LOG.md` và tài liệu ngữ cảnh/kế hoạch nếu phát hiện thay đổi.

## Cấu trúc
- `lib/features`: màn hình theo tính năng; `lib/providers`: trạng thái Provider; `lib/repositories`: truy cập dữ liệu ứng dụng.
- `lib/models`, `lib/services`, `lib/core`, `lib/shared`: model, dịch vụ, thành phần nền tảng và widget dùng chung.
- `server/src`: Express API; `supabase_schema.sql`: schema/RLS tham chiếu.
- Đọc `docs/PROJECT_CONTEXT.md` và `docs/DEVELOPMENT_PLAN.md` trước khi thực hiện công việc.

## Quy tắc dữ liệu và bảo mật
- Không đọc/in/chia sẻ nội dung `.env` hoặc `server/.env`; chỉ dùng file `.env.example` đã được làm sạch làm mẫu. Không ghi key, URL chứa bí mật, token hay thông tin tài khoản vào tài liệu, log hoặc mã Flutter.
- Không dùng service-role/secret key phía client. Server dùng đặc quyền phải xác minh access token và lọc mọi truy vấn theo `user_id`.
- Không áp dụng SQL, thay đổi schema/policy hay nạp dữ liệu Supabase nếu chưa được yêu cầu rõ ràng.
- Dữ liệu demo phải được giữ cục bộ trong repository/mocks; không seed vào môi trường Supabase.

## Quy trình thay đổi
- Xác nhận chức năng đã có trước khi sửa; không xóa hoặc thay thế tính năng chỉ để đơn giản hóa.
- Giữ UI hiện tại trừ khi yêu cầu nêu rõ thay đổi UI.
- Khi được yêu cầu xác minh, chạy kiểm tra phù hợp như `flutter analyze`; ghi nguyên trạng kết quả và hạn chế môi trường vào `TASK_LOG`.
- Cập nhật tài liệu sau mỗi nhiệm vụ. Không khẳng định backend hoạt động với Supabase nếu chưa kiểm tra kết nối thực tế.
