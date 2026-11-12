# Dream Diary – Nhật ký giấc mơ & Theo dõi giấc ngủ 🌙

Ứng dụng di động chuyên nghiệp giúp người dùng ghi chép giấc mơ, theo dõi chu kỳ giấc ngủ, đánh giá chất lượng và phân tích thói quen ngủ khoa học.

---

## 1. Mục tiêu và Tính năng chính

- 📖 **Nhật ký giấc mơ**: Ghi lại những giấc mơ kỳ thú mỗi sáng, phân loại theo 7 trạng thái cảm xúc (Vui vẻ, Bình yên, Hào hứng, Buồn bã, Sợ hãi, Kỳ lạ, Bình thường), đánh giá độ rõ nét (1-5 sao) và đánh dấu giấc mơ sáng suốt (Lucid Dream).
- 🛌 **Theo dõi giấc ngủ**: Cơ chế bắt đầu/kết thúc phiên ngủ với bộ đếm thời gian trực tiếp, tính toán tự động điểm chất lượng (0-100) dựa trên độ dài giấc ngủ và ước lượng các giai đoạn ngủ (Ngủ sâu, Ngủ nhẹ, REM).
- 📊 **Thống kê & Phân tích**: Biểu đồ trực quan thời lượng ngủ 7 ngày (fl_chart BarChart & LineChart), tỷ lệ phân bổ cảm xúc giấc mơ (PieChart), và lời khuyên cải thiện giấc ngủ.
- 📜 **Lịch sử toàn diện**: Lưu trữ và tìm kiếm lịch sử giấc mơ cùng các phiên ngủ theo mốc thời gian (Tất cả, 7 ngày qua, 30 ngày qua).
- 👤 **Hồ sơ cá nhân**: Quản lý mục tiêu giấc ngủ (Slider 5-12 giờ), bật/tắt nhắc nhở đi ngủ, tuỳ chỉnh giao diện ban đêm dịu mắt.
- 🎨 **Giao diện đẳng cấp**: Thiết kế Material Design 3 theo tông màu đêm (tím than, xanh đêm, tím lavender), bo góc mềm mại, typography sắc nét và hỗ trợ Dark Theme 100%.

---

## 2. Công nghệ sử dụng

| Công nghệ / Thư viện | Phiên bản | Mục đích |
|---|---|---|
| **Flutter & Dart** | SDK ^3.13.0 | Nền tảng phát triển ứng dụng di động đa nền tảng |
| **Material Design 3** | Latest | Hệ thống thiết kế chuẩn hiện đại của Google |
| **Provider** | ^6.1.2 | Quản lý trạng thái (State Management) sạch và tối ưu |
| **GoRouter** | ^14.8.1 | Quản lý điều hướng khai báo với StatefulShellRoute 5 tabs |
| **fl_chart** | ^1.0.0 | Hiển thị biểu đồ cột, biểu đồ đường và biểu đồ tròn |
| **SharedPreferences** | ^2.5.3 | Lưu trữ cục bộ các cài đặt, trạng thái phiên ngủ, thông tin user |
| **Dio** | ^5.8.0 | HTTP Client mạnh mẽ với Interceptors, sẵn sàng kết nối API |
| **Supabase Flutter** | ^2.18.3 | Chuẩn bị tích hợp xác thực và cơ sở dữ liệu PostgreSQL |
| **flutter_local_notifications** | ^19.4.0 | Quản lý thông báo nhắc nhở đi ngủ |

---

## 3. Cấu trúc thư mục (Feature-first)

```
lib/
├── main.dart                          # Entry point ứng dụng, khởi tạo services, orientation, overlay
├── app.dart                           # Root widget cấu hình MultiProvider, ThemeData, GoRouter
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            # Bảng màu phong cách đêm (Lavender, Midnight blue, Star gold...)
│   │   └── app_constants.dart         # Các hằng số cấu hình toàn ứng dụng
│   ├── errors/
│   │   └── app_exception.dart         # Hệ thống ngoại lệ tùy chỉnh (Network, Auth, Validation, Server...)
│   ├── network/
│   │   └── api_client.dart            # Client Dio cấu hình sẵn baseUrl, timeout, interceptors
│   ├── routes/
│   │   ├── app_routes.dart            # Định nghĩa hằng số tên và đường dẫn routes
│   │   └── app_router.dart            # GoRouter cấu hình StatefulShellRoute (5 tabs) & Sub-routes
│   ├── theme/
│   │   └── app_theme.dart             # Dark Theme hoàn chỉnh theo chuẩn Material 3
│   └── utils/
│       ├── date_formatter.dart        # Định dạng ngày giờ, khoảng cách tương đối, thời lượng ngủ
│       └── validators.dart            # Hàm kiểm tra hợp lệ email, mật khẩu, form dữ liệu
├── models/
│   ├── user_model.dart                # Model người dùng và cài đặt mục tiêu ngủ
│   ├── dream_model.dart               # Model giấc mơ, enum EmotionType và extensions
│   ├── sleep_session_model.dart       # Model phiên ngủ, thời lượng, điểm số, giai đoạn ngủ
│   └── sleep_statistics_model.dart    # Model dữ liệu thống kê tuần, phân bổ cảm xúc
├── repositories/
│   ├── dream_repository.dart          # CRUD giấc mơ (10 dữ liệu mẫu phong phú tiếng Việt)
│   └── sleep_repository.dart          # Lịch sử 7 phiên ngủ mẫu và tính toán thống kê
├── services/
│   ├── api_service.dart               # Service giao tiếp Backend Node.js / REST
│   ├── auth_service.dart              # Quản lý phiên đăng nhập, lưu SharedPreferences
│   ├── notification_service.dart      # Cấu hình kênh thông báo nhắc nhở giờ ngủ
│   └── sleep_tracking_service.dart    # Quản lý logic bắt đầu / kết thúc phiên theo dõi ngủ
├── providers/
│   ├── auth_provider.dart             # Quản lý trạng thái đăng nhập, người dùng, cài đặt
│   ├── dream_provider.dart            # Quản lý danh sách giấc mơ, lọc cảm xúc, tìm kiếm
│   └── sleep_provider.dart            # Quản lý phiên ngủ đang chạy, timer, thống kê
├── features/
│   ├── splash/presentation/           # Màn hình Splash với logo mặt trăng, sao lấp lánh
│   ├── onboarding/presentation/       # 3 trang giới thiệu tính năng, lưu trạng thái hoàn tất
│   ├── authentication/presentation/   # Đăng nhập, Đăng ký, Quên mật khẩu
│   ├── home/presentation/             # Trang chủ, tổng quan đêm qua, biểu đồ 7 ngày, nút thao tác nhanh
│   ├── dream_diary/presentation/      # Danh sách, thêm mới, xem chi tiết, chỉnh sửa giấc mơ
│   ├── sleep_tracking/presentation/   # Giao diện chuẩn bị, đang theo dõi timer, kết thúc phiên ngủ
│   ├── analytics/presentation/        # Biểu đồ đường thời lượng ngủ, biểu đồ tròn cảm xúc, mẹo ngủ
│   ├── history/presentation/          # Lịch sử dạng Tab (Giấc mơ / Phiên ngủ) và bộ lọc thời gian
│   └── profile/presentation/          # Thông tin cá nhân, slider mục tiêu ngủ, cài đặt, đăng xuất
└── shared/widgets/
    ├── app_button.dart                # Nút bấm tái sử dụng với gradient, loading, variants
    ├── app_text_field.dart            # Ô nhập liệu chuẩn đêm, ẩn/hiện mật khẩu
    ├── dream_card.dart                # Thẻ hiển thị giấc mơ bo góc, viền màu theo cảm xúc
    ├── sleep_quality_indicator.dart   # Vòng tròn điểm chất lượng ngủ (Xanh/Vàng/Đỏ)
    ├── section_header.dart            # Tiêu đề phân đoạn đồng nhất
    ├── empty_state.dart               # Widget thông báo trạng thái rỗng
    ├── loading_indicator.dart         # Widget trạng thái đang tải
    └── main_shell.dart                # Bottom Navigation Bar 5 mục điều hướng linh hoạt
```

---

## 4. Thanh điều hướng (Bottom Navigation Bar)

Ứng dụng sử dụng cấu trúc **Stateful Navigation Shell** với 5 mục điều hướng chính:
1. 🏠 **Trang chủ**: Lời chào, tổng quan đêm qua, biểu đồ tuần, thao tác nhanh.
2. 📖 **Giấc mơ**: Danh sách giấc mơ, tìm kiếm, lọc cảm xúc, thêm mới.
3. 🌙 **Giấc ngủ**: Theo dõi chu kỳ ngủ trực tiếp với bộ đếm thời gian.
4. 📊 **Phân tích**: Biểu đồ phân tích chuyên sâu và mẹo cải thiện.
5. 👤 **Cá nhân**: Mục tiêu số giờ ngủ, thông báo, đăng xuất.

---

## 5. Hướng dẫn chạy dự án

### Yêu cầu môi trường
- Đã cài đặt [Flutter SDK](https://flutter.dev/docs/get-started/install) (khuyến nghị >= 3.13.0).
- Trình giả lập Android Emulator hoặc thiết bị Android thật (đã bật Developer Mode & USB Debugging).

### Các bước khởi chạy

1. **Mở thư mục dự án**:
   ```bash
   cd nhatkygiacnguapp
   ```

2. **Cài đặt các gói phụ thuộc (Dependencies)**:
   ```bash
   flutter pub get
   ```

3. **Kiểm tra mã nguồn**:
   ```bash
   flutter analyze
   ```

4. **Khởi chạy ứng dụng**:
   ```bash
   flutter run
   ```

5. **Biên dịch bản cài đặt Android APK (Debug)**:
   ```bash
   flutter build apk --debug
   ```

---

## 6. Chuẩn bị kết nối Backend & Cơ sở dữ liệu

- **REST API Node.js**: Lớp `ApiClient` (sử dụng Dio) và `ApiService` đã sẵn sàng các endpoint đăng nhập, đăng ký, đồng bộ giấc mơ và phiên ngủ.
- **Supabase**: `supabase_flutter` đã được tích hợp trong dự án, sẵn sàng đọc thông tin URL và Anon Key từ `.env` để kết nối cơ sở dữ liệu PostgreSQL và Supabase Auth.
- **Dữ liệu mẫu (Mock data)**: Toàn bộ dữ liệu 10 giấc mơ sinh động và 7 phiên ngủ đã được tách riêng vào `repositories/`, dễ dàng chuyển đổi sang gọi API thực tế chỉ bằng một dòng lệnh.
