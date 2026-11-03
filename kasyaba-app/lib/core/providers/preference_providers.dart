import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/secure_storage_service.dart';

/// Account ids that should be left out of the safe-to-spend calculation.
final excludedAccountsProvider =
    StateNotifierProvider<ExcludedAccountsNotifier, Set<String>>((ref) {
      return ExcludedAccountsNotifier(ref.watch(secureStorageProvider));
    });

class ExcludedAccountsNotifier extends StateNotifier<Set<String>> {
  ExcludedAccountsNotifier(this._storage) : super(<String>{}) {
    unawaited(_load());
  }

  static const storageKey = 'excluded_safe_spend_accounts';

  final SecureStorageService _storage;
  int _revision = 0;

  Future<void> _load() async {
    final revision = _revision;
    try {
      final raw = await _storage.readRaw(storageKey);
      if (revision != _revision || raw == null || raw.trim().isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      final ids = decoded
          .whereType<String>()
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toSet();
      state = ids;
    } catch (_) {
      return;
    }
  }

  void toggle(String id) {
    if (id.isEmpty) return;
    final next = Set<String>.from(state);
    if (!next.remove(id)) {
      next.add(id);
    }
    _revision++;
    state = next;
    _persist();
  }

  void setExcluded(String id, bool excluded) {
    if (id.isEmpty) return;
    final next = Set<String>.from(state);
    if (excluded) {
      next.add(id);
    } else {
      next.remove(id);
    }
    _revision++;
    state = next;
    _persist();
  }

  bool isExcluded(String id) => state.contains(id);

  void _persist() {
    final encoded = jsonEncode(state.toList()..sort());
    unawaited(_write(encoded));
  }

  Future<void> _write(String value) async {
    try {
      await _storage.writeRaw(storageKey, value);
    } catch (_) {
      return;
    }
  }
}
