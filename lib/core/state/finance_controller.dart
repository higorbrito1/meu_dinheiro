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
  List<RecurringTransaction> recurring = [];
  List<Budget> budgets = [];
  List<Goal> goals = [];
  bool isLoading = true;
  int? memberFilterId;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    transactions = await repository.transactions();
    patrimony = await repository.patrimony();
    members = await repository.members();
    accounts = await repository.accounts();
    categories = await repository.categories();
    recurring = await repository.recurring();
    budgets = await repository.budgets();
    goals = await repository.goals();
    isLoading = false;
    notifyListeners();
  }

  int get income => transactions.where((x) => x.type == EntryType.income).fold(0, (sum, x) => sum + x.amountCents);
  int get expenses => transactions.where((x) => x.type == EntryType.expense).fold(0, (sum, x) => sum + x.amountCents);
  int get assets => patrimony.where((x) => !x.isDebt).fold(0, (sum, x) => sum + x.amountCents);
  int get debts => patrimony.where((x) => x.isDebt).fold(0, (sum, x) => sum + x.amountCents);
  List<TransactionEntry> get visibleTransactions => memberFilterId == null ? transactions : transactions.where((x) => x.memberId == memberFilterId).toList();
  void filterByMember(int? id) { memberFilterId = id; notifyListeners(); }

  Future<void> addTransaction({required EntryType type, required String description, required int amountCents}) async {
    await repository.addTransaction(TransactionEntry(id: 0, type: type, description: description, amountCents: amountCents, date: DateTime.now()));
    await load();
  }

  Future<void> addDetailedTransaction({required EntryType type, required String description, required int amountCents, required int memberId, required int accountId, int? categoryId, required String status, String? notes}) async {
    await repository.addTransaction(TransactionEntry(id: 0, type: type, description: description, amountCents: amountCents, date: DateTime.now(), memberId: memberId, accountId: accountId, categoryId: categoryId, status: status, notes: notes));
    await load();
  }

  Future<void> addMember(String name) async { await repository.addMember(HouseholdMember(id: 0, name: name)); await load(); }
  Future<void> addAccount({required String name, required String kind, int limitCents = 0}) async { await repository.addAccount(Account(id: 0, name: name, kind: kind, limitCents: limitCents)); await load(); }
  Future<void> addCategory({required String name, required EntryType type}) async { await repository.addCategory(Category(id: 0, name: name, type: type)); await load(); }

  Future<String> exportJson() => repository.exportJson();
  Future<void> importJson(String json) async { await repository.importJson(json); await load(); }

  Future<void> addPatrimony({required String name, required int amountCents, required bool isDebt}) async {
    await repository.addPatrimony(PatrimonyItem(id: 0, name: name, amountCents: amountCents, isDebt: isDebt));
    await load();
  }

  Future<void> addRecurring({required EntryType type, required String description, required int amountCents, required int dayOfMonth}) async { await repository.addRecurring(RecurringTransaction(id: 0, description: description, type: type, amountCents: amountCents, dayOfMonth: dayOfMonth)); await load(); }
  Future<void> addGoal({required String name, required int targetCents}) async { await repository.addGoal(Goal(id: 0, name: name, targetCents: targetCents)); await load(); }
  Future<void> addBudget({required int categoryId, required String month, required int amountCents}) async { await repository.addBudget(Budget(id: 0, categoryId: categoryId, month: month, amountCents: amountCents)); await load(); }

  Future<void> deleteTransaction(int id) async { await repository.deleteTransaction(id); await load(); }
  Future<void> deletePatrimony(int id) async { await repository.deletePatrimony(id); await load(); }
}
