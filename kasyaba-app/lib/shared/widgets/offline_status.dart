import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/theme/kasyaba_tokens.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/providers/api_providers.dart';

/// Formats the age of a cached snapshot using the compact product wording:
/// just now · Xm · Xh · Xd.
String formatOfflineAge(DateTime fetchedAt, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final difference = current.difference(fetchedAt);
  if (difference.inMinutes < 1) return 'just now';
  if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
  if (difference.inHours < 48) return '${difference.inHours}h ago';
  return '${difference.inDays}d ago';
}

/// Small "Offline · updated 2h ago" pill for read views backed by a cache
/// snapshot. Renders nothing while online or when the view has no cache.
class OfflineStatusBadge extends ConsumerWidget {
  final String snapshotKey;
  final EdgeInsetsGeometry? margin;

  const OfflineStatusBadge({
    super.key,
    required this.snapshotKey,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    if (isOnline) return const SizedBox.shrink();

    final fetchedAt = ref
        .watch(cachedSnapshotMetaProvider(snapshotKey))
        .valueOrNull;
    if (fetchedAt == null) return const SizedBox.shrink();

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: KasyabaTokens.bigStone,
            borderRadius: BorderRadius.circular(KasyabaTokens.radiusChip),
            border: Border.all(
              color: KasyabaTokens.apricot.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 13,
                color: KasyabaTokens.apricot,
              ),
              const SizedBox(width: 6),
              Text(
                'Offline · updated ${formatOfflineAge(fetchedAt)}',
                style: GoogleFonts.dmSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: KasyabaTokens.periwinkleGraySubtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact explanation shown next to actions that cannot run without a
/// connection. Apricot border on a bigStone card, matching the offline chip.
class NeedsInternetNotice extends StatelessWidget {
  final String message;
  final IconData icon;

  const NeedsInternetNotice({
    super.key,
    required this.message,
    this.icon = Icons.cloud_off_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: KasyabaTokens.bigStone,
        borderRadius: BorderRadius.circular(KasyabaTokens.radiusDialog),
        border: Border.all(
          color: KasyabaTokens.apricot.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: KasyabaTokens.apricot),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: KasyabaTokens.periwinkleGraySubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Positive counterpart for queueable writes: explains that the entry is
/// already safe on the device and will sync later.
class OfflineQueuedNote extends StatelessWidget {
  final String message;

  const OfflineQueuedNote({
    super.key,
    this.message = "Saved on this device — will sync when you're online.",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: KasyabaTokens.bigStone,
        borderRadius: BorderRadius.circular(KasyabaTokens.radiusDialog),
        border: Border.all(
          color: KasyabaTokens.bermuda.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_upload_outlined,
            size: 17,
            color: KasyabaTokens.bermuda,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
                color: KasyabaTokens.periwinkleGraySubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
