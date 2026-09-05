import '../models/finance_models.dart';

class FinanceCalculator {
  const FinanceCalculator();

  List<TransactionEntry> forMonth(List<TransactionEntry> entries, DateTime month) => entries.where((x) => x.date.year == month.year && x.date.month == month.month).toList();
  int income(Iterable<TransactionEntry> entries) => entries.where((x) => x.type == EntryType.income).fold(0, (sum, x) => sum + x.amountCents);
  int expenses(Iterable<TransactionEntry> entries) => entries.where((x) => x.type == EntryType.expense).fold(0, (sum, x) => sum + x.amountCents);
  int assets(Iterable<PatrimonyItem> entries) => entries.where((x) => !x.isDebt).fold(0, (sum, x) => sum + x.amountCents);
  int debts(Iterable<PatrimonyItem> entries) => entries.where((x) => x.isDebt).fold(0, (sum, x) => sum + x.amountCents);
  Map<String, int> expensesByDescription(Iterable<TransactionEntry> entries) {
    final result = <String, int>{};
    for (final entry in entries.where((x) => x.type == EntryType.expense)) { result[entry.description] = (result[entry.description] ?? 0) + entry.amountCents; }
    return result;
  }
}
