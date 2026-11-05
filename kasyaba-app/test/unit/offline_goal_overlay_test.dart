import 'package:flutter_test/flutter_test.dart';

import 'package:kasyaba/core/providers/api_providers.dart';

import '../support/fake_engine_stack.dart';

void main() {
  test('queued goal contribution reduces the local wallet balance overlay',
      () async {
    final stack = await FakeEngineStack.create();
    try {
      final before =
          await stack.container.read(accountBalancesProvider.future);
      final startingBalance = before['acct-1'];
      expect(startingBalance, isNotNull,
          reason: 'fake engine must expose an acct-1 balance');

      stack.cache.seedTransaction(
        id: 'queued-goal-deposit',
        type: 'goal_contribution',
        userId: 'qa-user',
        data: {
          'goalId': 'g1',
          'accountId': 'acct-1',
          'amount': '125.50',
          'contributedAt': DateTime.now().toUtc().toIso8601String(),
          'clientMutationId': '11111111-1111-4111-8111-111111111111',
        },
        createdAt: DateTime.now(),
      );

      stack.container.invalidate(accountBalancesProvider);
      final after = await stack.container.read(accountBalancesProvider.future);

      expect(
        after['acct-1'],
        closeTo(startingBalance! - 125.50, 0.001),
        reason: 'pending goal deposits must immediately reduce the wallet '
            'balance shown to the user',
      );
    } finally {
      await stack.dispose();
    }
  });
}
