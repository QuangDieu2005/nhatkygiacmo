import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Khởi tạo API Client từ cấu hình public hiện có.
  ApiClient.instance.init();

  // 2. Khởi tạo dịch vụ thông báo cục bộ
  await NotificationService.instance.init();

  // 3. Khóa hướng màn hình dọc (Portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 4. Cấu hình thanh trạng thái trong suốt phù hợp phong cách ban đêm
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF161B2E),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const DreamDiaryApp());
}
