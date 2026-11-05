import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/kasyaba_tokens.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../shared/widgets/kasyaba_card.dart';
import '../../../shared/widgets/motion_components.dart';
import '../../../shared/widgets/offline_status.dart';
import '../../../shared/widgets/pill_button.dart';
import '../widgets/data_backup_sheets.dart';

class BackupExportScreen extends ConsumerStatefulWidget {
  const BackupExportScreen({super.key});

  @override
  ConsumerState<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends ConsumerState<BackupExportScreen> {
  String _lastBackupLabel = 'Never';

  @override
  void initState() {
    super.initState();
    _loadLastBackup();
  }

  Future<void> _loadLastBackup() async {
    var label = 'Never';
    try {
      final raw = await ref
          .read(secureStorageProvider)
          .readRaw(lastBackupAtKey);
      final parsed = raw == null ? null : DateTime.tryParse(raw.trim());
      if (parsed != null) {
        label = DateFormat('MMM d, yyyy • h:mm a').format(parsed.toLocal());
      }
    } catch (_) {
      label = 'Never';
    }
    if (mounted) {
      setState(() => _lastBackupLabel = label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(isOnlineProvider);
    return Scaffold(
      backgroundColor: KasyabaTokens.ebony,
      body: Container(
        decoration: const BoxDecoration(gradient: KasyabaTokens.canvasGradient),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, KasyabaTokens.dockClearance),
            children: [
              FadeSlideEntrance.staggered(
                index: 0,
                child: Row(
                  children: [
                    SpringTouch(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: KasyabaTokens.bigStone,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: KasyabaTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: KasyabaTokens.periwinkleGray,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'Backup and export',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: KasyabaTokens.periwinkleGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isOnline) ...[
                const NeedsInternetNotice(
                  message:
                      'Backup, restore, and CSV export need a connection. Your saved data stays readable offline.',
                ),
                const SizedBox(height: 14),
              ],
              FadeSlideEntrance.staggered(
                index: 1,
                child: KasyabaCard(
                  variant: KasyabaCardVariant.hero,
                  padding: const EdgeInsets.all(19),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last backup',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KasyabaTokens.periwinkleGraySubtitle,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _lastBackupLabel,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: KasyabaTokens.periwinkleGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Back up now so you do not lose your records if you change phones.',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: KasyabaTokens.periwinkleGraySubtitle,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideEntrance.staggered(
                index: 2,
                child: _BackupActionCard(
                  icon: Icons.file_download_outlined,
                  title: 'Back up',
                  description:
                      'Saves everything: accounts, transactions, goals and bills (JSON).',
                  actionLabel: 'Create backup',
                  primary: true,
                  onPressed: !isOnline
                      ? null
                      : () async {
                          await showExportBackupSheet(context, ref);
                          if (mounted) _loadLastBackup();
                        },
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideEntrance.staggered(
                index: 3,
                child: _BackupActionCard(
                  icon: Icons.file_upload_outlined,
                  title: 'Restore',
                  description:
                      'Load a backup file. We check it before changing anything.',
                  actionLabel: 'Choose file',
                  primary: false,
                  onPressed: isOnline ? () => showRestoreBackupSheet(context, ref) : null,
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideEntrance.staggered(
                index: 4,
                child: _BackupActionCard(
                  icon: Icons.table_chart_outlined,
                  title: 'Export to CSV',
                  description:
                      'Your transactions as a spreadsheet for Excel or Google Sheets.',
                  actionLabel: 'Export transactions',
                  primary: false,
                  onPressed: isOnline ? () => showExportCsvSheet(context, ref) : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackupActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final bool primary;
  final VoidCallback? onPressed;

  const _BackupActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.primary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return KasyabaCard(
      padding: const EdgeInsets.all(19),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: KasyabaTokens.poloBlue30, width: 1),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: KasyabaTokens.periwinkleGray,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: KasyabaTokens.periwinkleGray,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: KasyabaTokens.periwinkleGraySubtitle,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PillButton(
            label: actionLabel,
            onPressed: onPressed,
            variant: primary
                ? PillButtonVariant.primary
                : PillButtonVariant.secondary,
          ),
        ],
      ),
    );
  }
}
