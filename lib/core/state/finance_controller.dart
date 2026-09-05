import 'package:flutter/foundation.dart';

import '../data/finance_repository.dart';
import '../models/finance_models.dart';

class FinanceController extends ChangeNotifier {
  FinanceController(this.repository);
  final FinanceRepository repository;
  List<TransactionEntry> transactions = [];
  List<PatrimonyItem> patrimony = [];
  List<HouseholdMember> members = [];
  List<Account> accounts = [];
  List<Category> categories = [];
  bool isLoading = true;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    transactions = await repository.transactions();
    patrimony = await repository.patrimony();
    members = await repository.members();
    accounts = await repository.accounts();
    categories = await repository.categories();
    isLoading = false;
    notifyListeners();
  }

  int get income => transactions.where((x) => x.type == EntryType.income).fold(0, (sum, x) => sum + x.amountCents);
  int get expenses => transactions.where((x) => x.type == EntryType.expense).fold(0, (sum, x) => sum + x.amountCents);
  int get assets => patrimony.where((x) => !x.isDebt).fold(0, (sum, x) => sum + x.amountCents);
  int get debts => patrimony.where((x) => x.isDebt).fold(0, (sum, x) => sum + x.amountCents);

  Future<void> addTransaction({required EntryType type, required String description, required int amountCents}) async {
    await repository.addTransaction(TransactionEntry(id: 0, type: type, description: description, amountCents: amountCents, date: DateTime.now()));
    await load();
  }

  Future<void> addPatrimony({required String name, required int amountCents, required bool isDebt}) async {
    await repository.addPatrimony(PatrimonyItem(id: 0, name: name, amountCents: amountCents, isDebt: isDebt));
    await load();
  }

  Future<void> deleteTransaction(int id) async { await repository.deleteTransaction(id); await load(); }
  Future<void> deletePatrimony(int id) async { await repository.deletePatrimony(id); await load(); }
}
