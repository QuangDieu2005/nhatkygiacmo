# DEVELOPMENT_PLAN — Dream Diary

Kế hoạch theo kiến trúc đã được chọn: **Flutter → Node.js/Express REST API → Supabase PostgreSQL/Auth**. Flutter không dùng Supabase Flutter trực tiếp cho CRUD nghiệp vụ. Tài liệu giai đoạn 2 chuẩn hóa hợp đồng; chưa triển khai kết nối hoặc migration.

## Giai đoạn 1 — Khảo sát/tài liệu hóa (hoàn thành)
- Ghi hiện trạng, luồng dữ liệu, fixtures, schema/API mismatch và rủi ro.
- Không sửa mã app/schema hoặc dữ liệu Supabase.

## Giai đoạn 2 — Chuẩn hóa kiến trúc/dữ liệu (tài liệu hoàn thành; quyết định nghiệp vụ còn mở)
- `docs/DATA_CONTRACT.md`: ánh xạ models ↔ DTO ↔ DB, required/optional/internal fields.
- `docs/API_SPECIFICATION.md`: endpoint và auth/session/error contract mục tiêu; nêu rõ endpoint hiện hữu/thiếu.
- `docs/DATABASE_MIGRATION_PROPOSAL.md`: schema đích và migration additive có điều kiện, chưa chạy.
- Các điểm còn mở: ngày giấc mơ khi đổi timezone, quality nullable, active sleep sync, profile/settings và dữ liệu migration hiện hữu. Duration do Express tính; GET trả JSON array trực tiếp ở bản đầu.

## Giai đoạn 3 — Chuẩn hóa cấu hình/bảo mật
- Thay config dự án cụ thể trong server `.env.example` bằng placeholder; không hiển thị env thật.
- Chốt env keys, URL theo Android emulator/device/web/prod, CORS origin allowlist, HTTPS.
- Chốt secure storage/session handling; không để SharedPreferences là nơi chứa bearer/refresh token.

## Giai đoạn 4 — Auth end-to-end
- Làm cho AuthService/AuthProvider tiêu dùng response DTO `user + session`, confirmation pending (HTTP 202/session null), refresh/expiry/logout.
- Thêm recovery/reset password qua backend; thiết kế safe email enumeration response.
- `ApiClient` gắn access token, single-flight refresh và retry có giới hạn; xử lý 401/403 rõ.

## Giai đoạn 5 — Hợp đồng dữ liệu và repository
- Cập nhật migration riêng đã phê duyệt; chạy staging/backup/restore trước production.
- Cập nhật model serialization/repositories và Express validation/routes theo contract mà không bỏ trường domain.
- Dream CRUD, completed sleep CRUD, owner scope và filter; GET trả array trực tiếp, chưa pagination. Express tính duration từ timestamp. Fixture tiếp tục chỉ cục bộ/test.
- Giữ active tracking local ở bản đầu nếu chưa có quyết định sync đa thiết bị.

## Giai đoạn 6 — Analytics, notification, kiểm chứng
- Tính thống kê trên dữ liệu thật, ghi rõ stage là ước lượng.
- Xác minh thông báo theo nền tảng và quyền.
- Test serialization, validation, auth lifecycle, owner isolation/RLS, migration staging, analyzer/build mục tiêu.

## Giai đoạn 7 — Phát hành
- HTTPS, CORS production allowlist, rate limits theo nhóm route, redact logs, secrets rotation/monitoring.
- Phê duyệt migration/release riêng; không seed fixture vào Supabase.

## Cổng hoàn thành
Không bắt đầu migration executable trước khi có inventory, quyết định các câu hỏi mở, backup/rollback và phê duyệt. Không đánh dấu CRUD/auth là live cho tới khi tích hợp và kiểm thử backend thật.
