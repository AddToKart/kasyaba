import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router/router.dart';
import '../core/connectivity/connectivity_service.dart';
import '../core/database/offline_sync_service.dart';
import '../core/notifications/bill_reminder_sync.dart';
import '../core/providers/api_providers.dart';
import 'theme/app_theme.dart';

class KasyabaApp extends ConsumerWidget {
  const KasyabaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final isOnline = ref.watch(isOnlineProvider);
    ref.watch(offlineSyncProvider);
    ref.watch(billReminderSyncProvider);
    ref.watch(accountBootstrapProvider);

    return MaterialApp.router(
      title: 'Kasyaba',
      debugShowCheckedModeBanner: false,
      // The product is designed as an obsidian dark experience; pin the theme
      // so light-mode devices do not render a half-configured light variant.
      theme: AppTheme().dark,
      darkTheme: AppTheme().dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      builder: (context, child) {
        return Stack(
          children: [
            child ?? const SizedBox.shrink(),
            if (!isOnline)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 4,
                  color: Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top + 4,
                      bottom: 8,
                      left: 16,
                      right: 16,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No internet connection',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
