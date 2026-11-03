import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';

class AddTransferScreen extends StatelessWidget {
  const AddTransferScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AddTransactionScreen(initialType: 'transfer');
  }
}
