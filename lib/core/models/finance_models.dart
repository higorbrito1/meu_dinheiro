enum EntryType { income, expense }

class TransactionEntry {
  const TransactionEntry({required this.id, required this.type, required this.description, required this.amountCents, required this.date});
  final int id;
  final EntryType type;
  final String description;
  final int amountCents;
  final DateTime date;

  Map<String, Object?> toMap() => {'id': id, 'type': type.name, 'description': description, 'amount_cents': amountCents, 'date': date.toIso8601String()};
  factory TransactionEntry.fromMap(Map<String, Object?> map) => TransactionEntry(
        id: map['id'] as int,
        type: map['type'] == 'income' ? EntryType.income : EntryType.expense,
        description: map['description'] as String,
        amountCents: map['amount_cents'] as int,
        date: DateTime.parse(map['date'] as String),
      );
}

class PatrimonyItem {
  const PatrimonyItem({required this.id, required this.name, required this.amountCents, required this.isDebt});
  final int id;
  final String name;
  final int amountCents;
  final bool isDebt;

  Map<String, Object?> toMap() => {'id': id, 'name': name, 'amount_cents': amountCents, 'is_debt': isDebt ? 1 : 0};
  factory PatrimonyItem.fromMap(Map<String, Object?> map) => PatrimonyItem(id: map['id'] as int, name: map['name'] as String, amountCents: map['amount_cents'] as int, isDebt: map['is_debt'] == 1);
}
