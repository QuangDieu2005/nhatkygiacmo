# DEVELOPMENT_PLAN — Dream Diary

Kế hoạch gợi ý theo thứ tự phụ thuộc; chưa triển khai trong giai đoạn 1. Giữ nguyên UI và kiến trúc feature/provider/repository, thay đổi nhỏ có thể kiểm chứng.

## Giai đoạn 1 — Khảo sát/tài liệu hóa (hoàn thành)
- Ghi hiện trạng kiến trúc, luồng dữ liệu, giả lập, schema/API mismatch, rủi ro và kết quả kiểm tra.
- Không sửa mã ứng dụng, schema, hoặc dữ liệu Supabase.

## Giai đoạn 2 — Chốt hợp đồng dữ liệu và cấu hình
- Quyết định REST backend là đường dữ liệu dự kiến hay Supabase Flutter trực tiếp; cập nhật tài liệu thống nhất.
- Đối chiếu field/model/schema/endpoint cho dream và sleep, gồm kiểu ID, tags, ngày, điểm chất lượng và giai đoạn ngủ.
- Thay cấu hình dự án có thật trong `server/.env.example` bằng placeholder; rà soát ignore rules và cách nạp biến môi trường mà không in secret.
- Chỉ lập migration đề xuất; xin yêu cầu riêng trước bất kỳ thay đổi DB nào.

## Giai đoạn 3 — Kết nối auth
- Thay mock auth bằng luồng đã chọn; xử lý xác nhận email, access/refresh token, logout và reset password.
- Chỉ giữ token theo cơ chế an toàn phù hợp nền tảng; không coi SharedPreferences là nơi lưu token bảo mật.
- Bảo đảm middleware xác minh JWT và quyền truy cập theo user.

## Giai đoạn 4 — Repository dữ liệu thật
- Nối dream CRUD, sleep records và xử lý lỗi/loading/empty state qua API/service.
- Giữ fixture riêng cho demo/test; không upload seed/mock.
- Làm rõ dữ liệu offline/đang theo dõi cần tồn tại cục bộ và cách đồng bộ.

## Giai đoạn 5 — Analytics, thông báo, độ tin cậy
- Tính analytics từ dữ liệu thật; phân biệt ước lượng giai đoạn ngủ với dữ liệu thiết bị đo.
- Xác minh lịch thông báo và quyền trên nền tảng được hỗ trợ.
- Thêm kiểm thử model/serialization, provider/repository, API và phân quyền đa tài khoản.

## Giai đoạn 6 — Phát hành
- Chạy analyzer, test, build các nền tảng mục tiêu; rà soát CORS/HTTPS/logging/secrets/RLS.
- Kiểm tra migration trên môi trường không production trước khi triển khai có phê duyệt.

## Tiêu chí hoàn thành đề xuất
- Tài liệu và luồng client/server/schema thống nhất.
- Không còn token giả hoặc CRUD giả trong luồng người dùng được đánh dấu production.
- Serialization tương thích với schema và API; dữ liệu owner-scoped.
- Analyzer/test/build phù hợp mục tiêu thành công; không lộ secret và không seed dữ liệu demo lên Supabase.
