import 'package:flutter/foundation.dart' hide Category;

import '../data/finance_repository.dart';
import '../domain/finance_calculator.dart';
import '../models/finance_models.dart';

class FinanceController extends ChangeNotifier {
  FinanceController(this.repository);
  final FinanceRepository repository;
  final calculator = const FinanceCalculator();
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
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    transactions = await repository.transactions();
    if (transactions.isNotEmpty) {
      final latest = transactions.first.date;
      selectedMonth = DateTime(latest.year, latest.month);
    }
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

  List<TransactionEntry> get monthTransactions =>
      calculator.forMonth(transactions, selectedMonth);
  int get income => calculator.income(monthTransactions);
  int get expenses => calculator.expenses(monthTransactions);
  int get assets => calculator.assets(patrimony);
  int get debts => calculator.debts(patrimony);
  List<TransactionEntry> get visibleTransactions => memberFilterId == null
      ? monthTransactions
      : monthTransactions.where((x) => x.memberId == memberFilterId).toList();
  void filterByMember(int? id) {
    memberFilterId = id;
    notifyListeners();
  }

  void selectMonth(DateTime value) {
    selectedMonth = DateTime(value.year, value.month);
    notifyListeners();
  }

  Future<void> addTransaction(
      {required EntryType type,
      required String description,
      required int amountCents}) async {
    await repository.addTransaction(TransactionEntry(
        id: 0,
        type: type,
        description: description,
        amountCents: amountCents,
        date: DateTime.now()));
    await load();
  }

  Future<void> addDetailedTransaction(
      {required EntryType type,
      required String description,
      required int amountCents,
      required int memberId,
      required int accountId,
      int? categoryId,
      required String status,
      String? notes}) async {
    await repository.addTransaction(TransactionEntry(
        id: 0,
        type: type,
        description: description,
        amountCents: amountCents,
        date: DateTime.now(),
        memberId: memberId,
        accountId: accountId,
        categoryId: categoryId,
        status: status,
        notes: notes));
    await load();
  }

  Future<void> addMember(String name) async {
    await repository.addMember(HouseholdMember(id: 0, name: name));
    await load();
  }

  Future<void> addAccount(
      {required String name, required String kind, int limitCents = 0}) async {
    await repository.addAccount(
        Account(id: 0, name: name, kind: kind, limitCents: limitCents));
    await load();
  }

  Future<void> addCategory(
      {required String name, required EntryType type}) async {
    await repository.addCategory(Category(id: 0, name: name, type: type));
    await load();
  }

  Future<String> exportJson() => repository.exportJson();
  Future<void> importJson(String json) async {
    await repository.importJson(json);
    await load();
  }

  Future<void> addPatrimony(
      {required String name,
      required int amountCents,
      required bool isDebt}) async {
    await repository.addPatrimony(PatrimonyItem(
        id: 0, name: name, amountCents: amountCents, isDebt: isDebt));
    await load();
  }

  Future<void> addRecurring(
      {required EntryType type,
      required String description,
      required int amountCents,
      required int dayOfMonth}) async {
    await repository.addRecurring(RecurringTransaction(
        id: 0,
        description: description,
        type: type,
        amountCents: amountCents,
        dayOfMonth: dayOfMonth));
    await load();
  }

  Future<void> addGoal({required String name, required int targetCents}) async {
    await repository.addGoal(Goal(id: 0, name: name, targetCents: targetCents));
    await load();
  }

  Future<void> addBudget(
      {required int categoryId,
      required String month,
      required int amountCents}) async {
    await repository.addBudget(Budget(
        id: 0, categoryId: categoryId, month: month, amountCents: amountCents));
    await load();
  }

  Future<void> deleteTransaction(int id) async {
    await repository.deleteTransaction(id);
    await load();
  }

  Future<void> deletePatrimony(int id) async {
    await repository.deletePatrimony(id);
    await load();
  }
}
