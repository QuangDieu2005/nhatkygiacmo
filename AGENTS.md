# Hướng dẫn cho Codex và người đóng góp

## Trạng thái và phạm vi
- Giai đoạn 1 (khảo sát/tài liệu hóa) và Giai đoạn 2 (chuẩn hóa kiến trúc, hợp đồng dữ liệu, API và đề xuất migration) đã hoàn thành ở mức tài liệu.
- Phạm vi hiện tại: chuẩn bị triển khai tích hợp thật theo tài liệu đã thống nhất; chỉ sửa source khi nhiệm vụ cho phép rõ. Đọc `docs/PROJECT_CONTEXT.md`, `docs/DEVELOPMENT_PLAN.md`, `docs/DATA_CONTRACT.md` và `docs/API_SPECIFICATION.md` trước khi triển khai.
- Ưu tiên giữ cấu trúc Flutter hiện tại, thay đổi nhỏ, có phạm vi rõ ràng; không tự ý thay đổi giao diện hoặc xóa chức năng.
- Sau mỗi nhiệm vụ, cập nhật `docs/TASK_LOG.md` và tài liệu liên quan.

## Cấu trúc và kiến trúc đích
- `lib/features`: màn hình theo tính năng; `lib/providers`: trạng thái Provider; `lib/repositories`: truy cập dữ liệu ứng dụng.
- `lib/models`, `lib/services`, `lib/core`, `lib/shared`: model, dịch vụ, thành phần nền tảng và widget dùng chung.
- `server/src`: Express REST API; `supabase_schema.sql`: schema tham chiếu.
- Kiến trúc đã chọn: Flutter → Node.js/Express REST API → Supabase PostgreSQL/Auth. Không dùng Supabase Flutter trực tiếp cho CRUD nghiệp vụ.

## Quy tắc dữ liệu và bảo mật
- Không đọc/in/chia sẻ nội dung `.env` hoặc `server/.env`; chỉ dùng file `.env.example` đã được làm sạch làm mẫu. Không ghi key, URL chứa bí mật, token hay thông tin tài khoản vào tài liệu, log hoặc mã Flutter.
- Không dùng service-role/secret key phía client. Server dùng đặc quyền phải xác minh access token và lọc mọi truy vấn theo `user_id` lấy từ danh tính đã xác minh.
- Không tự ý chạy migration, áp dụng SQL, thay đổi schema/policy hoặc dữ liệu Supabase. Chỉ soạn/đánh giá migration proposal nếu được yêu cầu; thực thi cần nhiệm vụ/phê duyệt rõ ràng.
- Dữ liệu demo phải được giữ cục bộ trong repository/mocks; không seed vào Supabase.

## Quy trình thay đổi
- Xác nhận chức năng đã có trước khi sửa; ưu tiên giữ nguyên kiến trúc và UI hiện tại.
- Khi được yêu cầu xác minh, chạy kiểm tra phù hợp và ghi nguyên trạng kết quả cùng giới hạn vào `TASK_LOG`.
- Không khẳng định backend hoạt động với Supabase nếu chưa kiểm tra kết nối thực tế.
