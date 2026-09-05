import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/finance_models.dart';

class FinanceRepository {
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    final path = p.join(await getDatabasesPath(), 'meu_dinheiro.db');
    _database = await openDatabase(path, version: 2, onCreate: _createSchema,
        onUpgrade: (db, old, _) async {
      if (old < 2) {
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN household_id INTEGER NOT NULL DEFAULT 1');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN member_id INTEGER NOT NULL DEFAULT 1');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN account_id INTEGER NOT NULL DEFAULT 1');
        await db
            .execute('ALTER TABLE transactions ADD COLUMN category_id INTEGER');
        await db.execute(
            'ALTER TABLE transactions ADD COLUMN status TEXT NOT NULL DEFAULT "paid"');
        await db.execute('ALTER TABLE transactions ADD COLUMN notes TEXT');
        await db.execute(
            'ALTER TABLE patrimony ADD COLUMN household_id INTEGER NOT NULL DEFAULT 1');
        await _createSchema(db, 2);
      }
    });
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute(
        'CREATE TABLE IF NOT EXISTS households (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS members (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, role TEXT NOT NULL)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS accounts (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, kind TEXT NOT NULL, limit_cents INTEGER NOT NULL DEFAULT 0)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, type TEXT NOT NULL)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, type TEXT NOT NULL, description TEXT NOT NULL, amount_cents INTEGER NOT NULL, date TEXT NOT NULL, member_id INTEGER NOT NULL, account_id INTEGER NOT NULL, category_id INTEGER, status TEXT NOT NULL DEFAULT "paid", notes TEXT)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS patrimony (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, amount_cents INTEGER NOT NULL, is_debt INTEGER NOT NULL)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS recurring_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, description TEXT NOT NULL, type TEXT NOT NULL, amount_cents INTEGER NOT NULL, day_of_month INTEGER NOT NULL, active INTEGER NOT NULL DEFAULT 1)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS budgets (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, category_id INTEGER NOT NULL, month TEXT NOT NULL, amount_cents INTEGER NOT NULL)');
    await db.execute(
        'CREATE TABLE IF NOT EXISTS goals (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, target_cents INTEGER NOT NULL, saved_cents INTEGER NOT NULL DEFAULT 0)');
    if ((await db.query('households')).isEmpty) {
      await db.insert('households', {'id': 1, 'name': 'Nossa casa'});
      await db.insert(
          'members', {'household_id': 1, 'name': 'Você', 'role': 'owner'});
      await db.insert(
          'members', {'household_id': 1, 'name': 'Esposa', 'role': 'member'});
      await db.insert('accounts', {
        'household_id': 1,
        'name': 'Conta principal',
        'kind': 'bank',
        'limit_cents': 0
      });
      for (final item in [
        ['Moradia', 'expense'],
        ['Alimentação', 'expense'],
        ['Transporte', 'expense'],
        ['Salário', 'income'],
        ['Outros', 'expense']
      ]) {
        await db.insert('categories',
            {'household_id': 1, 'name': item[0], 'type': item[1]});
      }
      await db.insert('transactions', {
        'household_id': 1,
        'type': 'income',
        'description': 'Salário PMPR',
        'amount_cents': 274288,
        'date': '2026-09-01T00:00:00.000',
        'member_id': 1,
        'account_id': 1,
        'category_id': 4,
        'status': 'paid'
      });
      for (final item in [
        ['Cartão MP', 14094],
        ['Cartão Itaú', 22757],
        ['Formatura PMPR', 25000],
        ['Plano Celular', 4500],
        ['Licenciamento Carro', 25127],
        ['Aluguel', 140000],
        ['Água', 20000],
        ['Luz', 15000],
        ['Internet (10)', 2668]
      ]) {
        await db.insert('transactions', {
          'household_id': 1,
          'type': 'expense',
          'description': item[0],
          'amount_cents': item[1],
          'date': '2026-09-01T00:00:00.000',
          'member_id': 1,
          'account_id': 1,
          'category_id': 5,
          'status': 'paid'
        });
      }
      await db.insert('patrimony', {
        'household_id': 1,
        'name': 'Palio',
        'amount_cents': 2732200,
        'is_debt': 0
      });
      await db.insert('patrimony', {
        'household_id': 1,
        'name': 'Biz',
        'amount_cents': 990400,
        'is_debt': 0
      });
      await db.insert('patrimony', {
        'household_id': 1,
        'name': 'Consignado BB',
        'amount_cents': 2149400,
        'is_debt': 1
      });
    }
  }

  Future<List<TransactionEntry>> transactions() async => (await (await database)
          .query('transactions', orderBy: 'date DESC, id DESC'))
      .map(TransactionEntry.fromMap)
      .toList();
  Future<List<PatrimonyItem>> patrimony() async =>
      (await (await database).query('patrimony', orderBy: 'is_debt, name'))
          .map(PatrimonyItem.fromMap)
          .toList();
  Future<List<HouseholdMember>> members() async =>
      (await (await database).query('members', orderBy: 'id'))
          .map(HouseholdMember.fromMap)
          .toList();
  Future<List<Account>> accounts() async =>
      (await (await database).query('accounts', orderBy: 'name'))
          .map(Account.fromMap)
          .toList();
  Future<List<Category>> categories() async =>
      (await (await database).query('categories', orderBy: 'name'))
          .map(Category.fromMap)
          .toList();
  Future<List<RecurringTransaction>> recurring() async =>
      (await (await database)
              .query('recurring_transactions', orderBy: 'day_of_month'))
          .map(RecurringTransaction.fromMap)
          .toList();
  Future<List<Budget>> budgets() async =>
      (await (await database).query('budgets', orderBy: 'month'))
          .map(Budget.fromMap)
          .toList();
  Future<List<Goal>> goals() async =>
      (await (await database).query('goals', orderBy: 'id'))
          .map(Goal.fromMap)
          .toList();
  Future<void> addTransaction(TransactionEntry x) async =>
      (await database).insert('transactions', {
        'type': x.type.name,
        'description': x.description,
        'amount_cents': x.amountCents,
        'date': x.date.toIso8601String(),
        'member_id': x.memberId,
        'account_id': x.accountId,
        'category_id': x.categoryId,
        'status': x.status,
        'notes': x.notes
      });
  Future<void> addMember(HouseholdMember x) async => (await database).insert(
      'members', {'household_id': 1, 'name': x.name, 'role': x.role.name});
  Future<void> addAccount(Account x) async =>
      (await database).insert('accounts', {
        'household_id': 1,
        'name': x.name,
        'kind': x.kind,
        'limit_cents': x.limitCents
      });
  Future<void> addCategory(Category x) async => (await database).insert(
      'categories', {'household_id': 1, 'name': x.name, 'type': x.type.name});
  Future<void> deleteTransaction(int id) async =>
      (await database).delete('transactions', where: 'id = ?', whereArgs: [id]);
  Future<void> addPatrimony(PatrimonyItem x) async {
    final values = x.toMap()..remove('id');
    await (await database).insert('patrimony', {'household_id': 1, ...values});
  }

  Future<void> deletePatrimony(int id) async =>
      (await database).delete('patrimony', where: 'id = ?', whereArgs: [id]);
  Future<void> addRecurring(RecurringTransaction x) async {
    final values = x.toMap()..remove('id');
    await (await database)
        .insert('recurring_transactions', {'household_id': 1, ...values});
  }

  Future<void> addBudget(Budget x) async {
    final values = x.toMap()..remove('id');
    await (await database).insert('budgets', {'household_id': 1, ...values});
  }

  Future<void> addGoal(Goal x) async {
    final values = x.toMap()..remove('id');
    await (await database).insert('goals', {'household_id': 1, ...values});
  }

  Future<String> exportJson() async {
    final db = await database;
    final tables = [
      'households',
      'members',
      'accounts',
      'categories',
      'transactions',
      'patrimony',
      'recurring_transactions',
      'budgets',
      'goals'
    ];
    final payload = <String, Object?>{
      'schema_version': 2,
      'exported_at': DateTime.now().toIso8601String()
    };
    for (final table in tables) {
      payload[table] = await db.query(table);
    }
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> importJson(String json) async {
    final payload = jsonDecode(json) as Map<String, dynamic>;
    if (payload['schema_version'] is! int || payload['schema_version'] < 1) {
      throw const FormatException('Backup inválido');
    }
    final db = await database;
    await db.transaction((tx) async {
      for (final table in [
        'transactions',
        'patrimony',
        'recurring_transactions',
        'budgets',
        'goals',
        'categories',
        'accounts',
        'members',
        'households'
      ]) {
        await tx.delete(table);
      }
      for (final table in [
        'households',
        'members',
        'accounts',
        'categories',
        'transactions',
        'patrimony',
        'recurring_transactions',
        'budgets',
        'goals'
      ]) {
        final rows = payload[table];
        if (rows is List) {
          for (final row in rows) {
            await tx.insert(table, Map<String, Object?>.from(row as Map));
          }
        }
      }
    });
  }
}
