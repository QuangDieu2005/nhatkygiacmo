import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';
import 'core/network/api_client.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Tải biến môi trường .env nếu có
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Nếu chưa có .env sẽ sử dụng các giá trị mặc định từ AppConstants
  }

  // 2. Khởi tạo API Client
  ApiClient.instance.init();

  // 3. Khởi tạo dịch vụ thông báo cục bộ
  await NotificationService.instance.init();

  // 4. Khóa hướng màn hình dọc (Portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 5. Cấu hình thanh trạng thái trong suốt phù hợp phong cách ban đêm
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF161B2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // TODO: Tích hợp Supabase khi có thông tin dự án thực tế:
  // await Supabase.initialize(
  //   url: dotenv.env['SUPABASE_URL'] ?? AppConstants.supabaseUrl,
  //   anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? AppConstants.supabaseAnonKey,
  // );

  runApp(const DreamDiaryApp());
}
