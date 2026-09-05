import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/finance_models.dart';

class FinanceRepository {
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    final path = p.join(await getDatabasesPath(), 'meu_dinheiro.db');
    _database = await openDatabase(path, version: 2, onCreate: _createSchema, onUpgrade: (db, old, _) async {
      if (old < 2) {
        await db.execute('ALTER TABLE transactions ADD COLUMN household_id INTEGER NOT NULL DEFAULT 1');
        await db.execute('ALTER TABLE transactions ADD COLUMN member_id INTEGER NOT NULL DEFAULT 1');
        await db.execute('ALTER TABLE transactions ADD COLUMN account_id INTEGER NOT NULL DEFAULT 1');
        await db.execute('ALTER TABLE transactions ADD COLUMN category_id INTEGER');
        await db.execute('ALTER TABLE transactions ADD COLUMN status TEXT NOT NULL DEFAULT "paid"');
        await db.execute('ALTER TABLE transactions ADD COLUMN notes TEXT');
        await db.execute('ALTER TABLE patrimony ADD COLUMN household_id INTEGER NOT NULL DEFAULT 1');
        await _createSchema(db, 2);
      }
    });
    return _database!;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('CREATE TABLE IF NOT EXISTS households (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
    await db.execute('CREATE TABLE IF NOT EXISTS members (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, role TEXT NOT NULL)');
    await db.execute('CREATE TABLE IF NOT EXISTS accounts (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, kind TEXT NOT NULL, limit_cents INTEGER NOT NULL DEFAULT 0)');
    await db.execute('CREATE TABLE IF NOT EXISTS categories (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, type TEXT NOT NULL)');
    await db.execute('CREATE TABLE IF NOT EXISTS transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, type TEXT NOT NULL, description TEXT NOT NULL, amount_cents INTEGER NOT NULL, date TEXT NOT NULL, member_id INTEGER NOT NULL, account_id INTEGER NOT NULL, category_id INTEGER, status TEXT NOT NULL DEFAULT "paid", notes TEXT)');
    await db.execute('CREATE TABLE IF NOT EXISTS patrimony (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, amount_cents INTEGER NOT NULL, is_debt INTEGER NOT NULL)');
    await db.execute('CREATE TABLE IF NOT EXISTS recurring_transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, description TEXT NOT NULL, type TEXT NOT NULL, amount_cents INTEGER NOT NULL, day_of_month INTEGER NOT NULL, active INTEGER NOT NULL DEFAULT 1)');
    await db.execute('CREATE TABLE IF NOT EXISTS budgets (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, category_id INTEGER NOT NULL, month TEXT NOT NULL, amount_cents INTEGER NOT NULL)');
    await db.execute('CREATE TABLE IF NOT EXISTS goals (id INTEGER PRIMARY KEY AUTOINCREMENT, household_id INTEGER NOT NULL, name TEXT NOT NULL, target_cents INTEGER NOT NULL, saved_cents INTEGER NOT NULL DEFAULT 0)');
    if ((await db.query('households')).isEmpty) {
      await db.insert('households', {'id': 1, 'name': 'Nossa casa'});
      await db.insert('members', {'household_id': 1, 'name': 'Você', 'role': 'owner'});
      await db.insert('members', {'household_id': 1, 'name': 'Esposa', 'role': 'member'});
      await db.insert('accounts', {'household_id': 1, 'name': 'Conta principal', 'kind': 'bank', 'limit_cents': 0});
      for (final item in [['Moradia', 'expense'], ['Alimentação', 'expense'], ['Transporte', 'expense'], ['Salário', 'income'], ['Outros', 'expense']]) { await db.insert('categories', {'household_id': 1, 'name': item[0], 'type': item[1]}); }
    }
  }

  Future<List<TransactionEntry>> transactions() async => (await (await database).query('transactions', orderBy: 'date DESC, id DESC')).map(TransactionEntry.fromMap).toList();
  Future<List<PatrimonyItem>> patrimony() async => (await (await database).query('patrimony', orderBy: 'is_debt, name')).map(PatrimonyItem.fromMap).toList();
  Future<List<HouseholdMember>> members() async => (await (await database).query('members', orderBy: 'id')).map(HouseholdMember.fromMap).toList();
  Future<List<Account>> accounts() async => (await (await database).query('accounts', orderBy: 'name')).map(Account.fromMap).toList();
  Future<List<Category>> categories() async => (await (await database).query('categories', orderBy: 'name')).map(Category.fromMap).toList();
  Future<void> addTransaction(TransactionEntry x) async => (await database).insert('transactions', {'type': x.type.name, 'description': x.description, 'amount_cents': x.amountCents, 'date': x.date.toIso8601String(), 'member_id': x.memberId, 'account_id': x.accountId, 'category_id': x.categoryId, 'status': x.status, 'notes': x.notes});
  Future<void> deleteTransaction(int id) async => (await database).delete('transactions', where: 'id = ?', whereArgs: [id]);
  Future<void> addPatrimony(PatrimonyItem x) async => (await database).insert('patrimony', {'household_id': 1, ...x.toMap()..remove('id')});
  Future<void> deletePatrimony(int id) async => (await database).delete('patrimony', where: 'id = ?', whereArgs: [id]);
}
