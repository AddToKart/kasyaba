import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../dashboard/widgets/dashboard_tokens.dart';
import '../../../shared/widgets/motion_components.dart';
import '../widgets/data_backup_sheets.dart';

/// ─────────────────────────────────────────────────────────────
///  1:1 Figma Backup and Export Screen (Node 42:6929)
/// ─────────────────────────────────────────────────────────────
class BackupExportScreen extends ConsumerStatefulWidget {
  const BackupExportScreen({super.key});

  @override
  ConsumerState<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends ConsumerState<BackupExportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DashboardTokens.ebony,
      body: Container(
        decoration: const BoxDecoration(
          gradient: DashboardTokens.canvasGradient,
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    // Header row: 50x50 squircle back button + Title
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
                                color: DashboardTokens.bigStone,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: DashboardTokens.poloBlue22,
                                  width: 1,
                                ),
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                color: DashboardTokens.periwinkleGray,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Backup and export',
                            style: TextStyle(
                              fontFamily: 'Bricolage Grotesque',
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: DashboardTokens.periwinkleGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Last Backup Hero Card
                    FadeSlideEntrance.staggered(
                      index: 1,
                      child: Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                          color: DashboardTokens.cello60,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: DashboardTokens.poloBlue30,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Last backup',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: DashboardTokens.periwinkleGraySubtitle,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Never',
                              style: TextStyle(
                                fontFamily: 'Bricolage Grotesque',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: DashboardTokens.periwinkleGray,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Back up now so you do not lose your records if you change phones.',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: DashboardTokens.periwinkleGraySubtitle,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card 1: Back up (JSON)
                    FadeSlideEntrance.staggered(
                      index: 2,
                      child: Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
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
                                    borderRadius: BorderRadius.circular(23),
                                    border: Border.all(
                                      color: DashboardTokens.poloBlue30,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.file_download_outlined,
                                      color: DashboardTokens.periwinkleGray,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Back up',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: DashboardTokens.periwinkleGray,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Saves everything: accounts, transactions, goals and bills (JSON).',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: DashboardTokens.periwinkleGraySubtitle,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SpringTouch(
                              onTap: () => showExportBackupSheet(context, ref),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  color: DashboardTokens.periwinkleGray,
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Create backup',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: DashboardTokens.ebony,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card 2: Restore (JSON)
                    FadeSlideEntrance.staggered(
                      index: 3,
                      child: Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
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
                                    borderRadius: BorderRadius.circular(23),
                                    border: Border.all(
                                      color: DashboardTokens.poloBlue30,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.file_upload_outlined,
                                      color: DashboardTokens.periwinkleGray,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Restore',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: DashboardTokens.periwinkleGray,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Load a backup file. We check it before changing anything.',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: DashboardTokens.periwinkleGraySubtitle,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SpringTouch(
                              onTap: () => showRestoreBackupSheet(context, ref),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: DashboardTokens.kashmirBlue,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Choose file',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: DashboardTokens.periwinkleGray,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Card 3: Export to CSV
                    FadeSlideEntrance.staggered(
                      index: 4,
                      child: Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                          color: DashboardTokens.bigStone,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: DashboardTokens.poloBlue22,
                            width: 1,
                          ),
                        ),
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
                                    borderRadius: BorderRadius.circular(23),
                                    border: Border.all(
                                      color: DashboardTokens.poloBlue30,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.table_chart_outlined,
                                      color: DashboardTokens.periwinkleGray,
                                      size: 22,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Export to CSV',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          color: DashboardTokens.periwinkleGray,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Your transactions as a spreadsheet for Excel or Google Sheets.',
                                        style: TextStyle(
                                          fontFamily: 'DM Sans',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          color: DashboardTokens.periwinkleGraySubtitle,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SpringTouch(
                              onTap: () => showExportCsvSheet(context, ref),
                              child: Container(
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: DashboardTokens.kashmirBlue,
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Export transactions',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: DashboardTokens.periwinkleGray,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
