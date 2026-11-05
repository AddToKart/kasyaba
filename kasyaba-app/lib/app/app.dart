import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router/router.dart';
import 'theme/kasyaba_tokens.dart';
import '../core/connectivity/connectivity_service.dart';
import '../core/database/offline_sync_service.dart';
import '../core/notifications/bill_reminder_sync.dart';
import '../core/notifications/notification_sync.dart';
import '../core/providers/api_providers.dart';
import '../core/providers/session_refresh_provider.dart';
import '../core/providers/theme_provider.dart';
import 'theme/app_theme.dart';

class KasyabaApp extends ConsumerStatefulWidget {
  const KasyabaApp({super.key});

  @override
  ConsumerState<KasyabaApp> createState() => _KasyabaAppState();
}

class _KasyabaAppState extends ConsumerState<KasyabaApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      invalidateOnResume(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final isOnline = ref.watch(isOnlineProvider);
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(offlineSyncProvider);
    ref.watch(billReminderSyncProvider);
    ref.watch(paydayReminderSyncProvider);
    ref.watch(alertNotificationSyncProvider);
    ref.watch(goalMilestoneSyncProvider);
    ref.watch(weeklySummarySyncProvider);
    ref.watch(accountBootstrapProvider);
    ref.watch(sessionDataResetProvider);

    return MaterialApp.router(
      title: 'Kasyaba',
      debugShowCheckedModeBanner: false,
      theme: AppTheme().light,
      darkTheme: AppTheme().dark,
      themeMode: themeMode,
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
                    decoration: BoxDecoration(
                      color: KasyabaTokens.bigStone,
                      borderRadius: BorderRadius.circular(
                        KasyabaTokens.radiusDialog,
                      ),
                      border: Border.all(color: KasyabaTokens.apricot),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          color: KasyabaTokens.apricot,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'No internet connection',
                            style: GoogleFonts.dmSans(
                              color: KasyabaTokens.periwinkleGray,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
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
