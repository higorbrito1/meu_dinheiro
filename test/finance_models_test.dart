import 'package:flutter_test/flutter_test.dart';
import 'package:meu_dinheiro/core/models/finance_models.dart';

void main() {
  test('serializes a transaction using integer cents', () {
    final entry = TransactionEntry(id: 1, type: EntryType.expense, description: 'Aluguel', amountCents: 140000, date: DateTime(2026, 9, 1));
    final restored = TransactionEntry.fromMap(entry.toMap());
    expect(restored.amountCents, 140000);
    expect(restored.type, EntryType.expense);
    expect(restored.description, 'Aluguel');
  });
}
