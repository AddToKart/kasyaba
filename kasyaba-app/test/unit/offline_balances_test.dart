// Wallet balances are part of the privacy policy's device-cache list
// ("wallets"), so they must be written to the offline snapshot cache and
// served from it when the balance endpoint is unreachable.
import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/database/cache_service.dart';
import 'package:kasyaba/core/providers/api_providers.dart';

import '../support/fake_engine_stack.dart';

void main() {
  test('balances are cached online and served from cache when the endpoint fails', () async {
    final stack = await FakeEngineStack.create();
    try {
      final online = await stack.container.read(accountBalancesProvider.future);
      expect(online['acct-1'], 1000.00);

      final snapshot = await stack.cache.getSnapshot(
        'qa-user',
        CacheService.snapshotKeyBalances,
      );
      expect(
        snapshot,
        isNotNull,
        reason: 'balances must be written to the offline snapshot cache',
      );
      expect(snapshot!.json, contains('1000'));

      // Simulate losing connectivity to the API: only the balance endpoint
      // fails while the cached accounts list keeps resolving.
      stack.api.on(
        'GET',
        RegExp(r'^/accounts/[^/]+/balance$'),
        (_) => const FakeApiResponse(
          {'error': {'message': 'down'}},
          statusCode: 500,
        ),
      );
      stack.container.invalidate(accountBalancesProvider);
      final cached = await stack.container.read(accountBalancesProvider.future);

      expect(
        cached['acct-1'],
        1000.00,
        reason: 'offline reads must serve the cached wallet balances',
      );
    } finally {
      await stack.dispose();
    }
  });
}
