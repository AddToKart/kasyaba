import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme/app_theme.dart';
import 'core/api/api_client.dart';
import 'core/errors/error_handlers.dart';
import 'core/notifications/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  installGlobalErrorHandlers();

  // A release build must be compiled with the production API URL:
  //   flutter build appbundle --dart-define=API_BASE_URL=https://api.example.com
  if (kReleaseMode && kApiBaseUrl.isEmpty) {
    runApp(const _ConfigurationErrorApp());
    return;
  }

  // Notification setup must never prevent the app from starting (for example
  // when the user revoked the permission or the launcher icon is unavailable).
  try {
    await NotificationService.instance.init();
  } catch (error, stack) {
    debugPrint('Notification setup failed: $error\n$stack');
  }

  runApp(const ProviderScope(child: KasyabaApp()));
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        backgroundColor: AppColors.obsidian,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'This build is missing its API configuration.\n\n'
              'Please install the official release from Google Play.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
