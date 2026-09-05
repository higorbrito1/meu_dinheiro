enum EntryType { income, expense }

enum MemberRole { owner, member }

class HouseholdMember {
  const HouseholdMember(
      {required this.id, required this.name, this.role = MemberRole.member});
  final int id;
  final String name;
  final MemberRole role;
  Map<String, Object?> toMap() => {'id': id, 'name': name, 'role': role.name};
  factory HouseholdMember.fromMap(Map<String, Object?> m) => HouseholdMember(
      id: m['id'] as int,
      name: m['name'] as String,
      role: m['role'] == 'owner' ? MemberRole.owner : MemberRole.member);
}

class Account {
  const Account(
      {required this.id,
      required this.name,
      required this.kind,
      this.limitCents = 0});
  final int id;
  final String name;
  final String kind;
  final int limitCents;
  Map<String, Object?> toMap() =>
      {'id': id, 'name': name, 'kind': kind, 'limit_cents': limitCents};
  factory Account.fromMap(Map<String, Object?> m) => Account(
      id: m['id'] as int,
      name: m['name'] as String,
      kind: m['kind'] as String,
      limitCents: (m['limit_cents'] as int?) ?? 0);
}

class Category {
  const Category({required this.id, required this.name, required this.type});
  final int id;
  final String name;
  final EntryType type;
  Map<String, Object?> toMap() => {'id': id, 'name': name, 'type': type.name};
  factory Category.fromMap(Map<String, Object?> m) => Category(
      id: m['id'] as int,
      name: m['name'] as String,
      type: m['type'] == 'income' ? EntryType.income : EntryType.expense);
}

class TransactionEntry {
  const TransactionEntry(
      {required this.id,
      required this.type,
      required this.description,
      required this.amountCents,
      required this.date,
      this.memberId = 1,
      this.accountId = 1,
      this.categoryId,
      this.status = 'paid',
      this.notes});
  final int id;
  final EntryType type;
  final String description;
  final int amountCents;
  final DateTime date;
  final int memberId;
  final int accountId;
  final int? categoryId;
  final String status;
  final String? notes;
  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'description': description,
        'amount_cents': amountCents,
        'date': date.toIso8601String(),
        'member_id': memberId,
        'account_id': accountId,
        'category_id': categoryId,
        'status': status,
        'notes': notes
      };
  factory TransactionEntry.fromMap(Map<String, Object?> m) => TransactionEntry(
      id: m['id'] as int,
      type: m['type'] == 'income' ? EntryType.income : EntryType.expense,
      description: m['description'] as String,
      amountCents: m['amount_cents'] as int,
      date: DateTime.parse(m['date'] as String),
      memberId: (m['member_id'] as int?) ?? 1,
      accountId: (m['account_id'] as int?) ?? 1,
      categoryId: m['category_id'] as int?,
      status: (m['status'] as String?) ?? 'paid',
      notes: m['notes'] as String?);
}

class PatrimonyItem {
  const PatrimonyItem(
      {required this.id,
      required this.name,
      required this.amountCents,
      required this.isDebt});
  final int id;
  final String name;
  final int amountCents;
  final bool isDebt;
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'amount_cents': amountCents,
        'is_debt': isDebt ? 1 : 0
      };
  factory PatrimonyItem.fromMap(Map<String, Object?> m) => PatrimonyItem(
      id: m['id'] as int,
      name: m['name'] as String,
      amountCents: m['amount_cents'] as int,
      isDebt: m['is_debt'] == 1);
}

class RecurringTransaction {
  const RecurringTransaction(
      {required this.id,
      required this.description,
      required this.type,
      required this.amountCents,
      required this.dayOfMonth,
      this.active = true});
  final int id;
  final String description;
  final EntryType type;
  final int amountCents;
  final int dayOfMonth;
  final bool active;
  Map<String, Object?> toMap() => {
        'id': id,
        'description': description,
        'type': type.name,
        'amount_cents': amountCents,
        'day_of_month': dayOfMonth,
        'active': active ? 1 : 0
      };
  factory RecurringTransaction.fromMap(Map<String, Object?> m) =>
      RecurringTransaction(
          id: m['id'] as int,
          description: m['description'] as String,
          type: m['type'] == 'income' ? EntryType.income : EntryType.expense,
          amountCents: m['amount_cents'] as int,
          dayOfMonth: m['day_of_month'] as int,
          active: m['active'] == 1);
}

class Budget {
  const Budget(
      {required this.id,
      required this.categoryId,
      required this.month,
      required this.amountCents});
  final int id;
  final int categoryId;
  final String month;
  final int amountCents;
  Map<String, Object?> toMap() => {
        'id': id,
        'category_id': categoryId,
        'month': month,
        'amount_cents': amountCents
      };
  factory Budget.fromMap(Map<String, Object?> m) => Budget(
      id: m['id'] as int,
      categoryId: m['category_id'] as int,
      month: m['month'] as String,
      amountCents: m['amount_cents'] as int);
}

class Goal {
  const Goal(
      {required this.id,
      required this.name,
      required this.targetCents,
      this.savedCents = 0});
  final int id;
  final String name;
  final int targetCents;
  final int savedCents;
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'target_cents': targetCents,
        'saved_cents': savedCents
      };
  factory Goal.fromMap(Map<String, Object?> m) => Goal(
      id: m['id'] as int,
      name: m['name'] as String,
      targetCents: m['target_cents'] as int,
      savedCents: m['saved_cents'] as int);
}
