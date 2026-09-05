import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/data/finance_repository.dart';
import 'core/state/finance_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = FinanceController(FinanceRepository());
  await controller.load();
  runApp(ChangeNotifierProvider.value(
      value: controller, child: const MeuDinheiroApp()));
}
