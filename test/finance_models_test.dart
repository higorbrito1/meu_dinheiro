import 'package:flutter_test/flutter_test.dart';
import 'package:meu_dinheiro/core/models/finance_models.dart';
import 'package:meu_dinheiro/core/domain/finance_calculator.dart';

void main() {
  test('serializes a transaction using integer cents', () {
    final entry = TransactionEntry(
        id: 1,
        type: EntryType.expense,
        description: 'Aluguel',
        amountCents: 140000,
        date: DateTime(2026, 9, 1));
    final restored = TransactionEntry.fromMap(entry.toMap());
    expect(restored.amountCents, 140000);
    expect(restored.type, EntryType.expense);
    expect(restored.description, 'Aluguel');
  });

  test('calculates household monthly totals in cents', () {
    final entries = [
      TransactionEntry(
          id: 1,
          type: EntryType.income,
          description: 'Salário',
          amountCents: 300000,
          date: DateTime(2026, 9, 1)),
      TransactionEntry(
          id: 2,
          type: EntryType.expense,
          description: 'Aluguel',
          amountCents: 140000,
          date: DateTime(2026, 9, 5)),
      TransactionEntry(
          id: 3,
          type: EntryType.expense,
          description: 'Aluguel',
          amountCents: 10000,
          date: DateTime(2026, 8, 5)),
    ];
    const calculator = FinanceCalculator();
    final month = calculator.forMonth(entries, DateTime(2026, 9));
    expect(calculator.income(month), 300000);
    expect(calculator.expenses(month), 140000);
    expect(calculator.expensesByDescription(month)['Aluguel'], 140000);
  });
}
