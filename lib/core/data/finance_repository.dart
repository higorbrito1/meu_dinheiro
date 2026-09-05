import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/finance_models.dart';

class FinanceRepository {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final path = p.join(await getDatabasesPath(), 'meu_dinheiro.db');
    _database = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('CREATE TABLE transactions (id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, description TEXT NOT NULL, amount_cents INTEGER NOT NULL, date TEXT NOT NULL)');
      await db.execute('CREATE TABLE patrimony (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, amount_cents INTEGER NOT NULL, is_debt INTEGER NOT NULL)');
      await db.insert('transactions', {'type': 'income', 'description': 'Salário PMPR', 'amount_cents': 274288, 'date': '2026-09-01T00:00:00.000'});
      for (final item in [
        ['Cartão MP', 14094], ['Cartão Itaú', 22757], ['Formatura PMPR', 25000], ['Plano Celular', 4500],
        ['Licenciamento Carro', 25127], ['Aluguel', 140000], ['Água', 20000], ['Luz', 15000], ['Internet (10)', 2668],
      ]) {
        await db.insert('transactions', {'type': 'expense', 'description': item[0], 'amount_cents': item[1], 'date': '2026-09-01T00:00:00.000'});
      }
      await db.insert('patrimony', {'name': 'Palio', 'amount_cents': 2732200, 'is_debt': 0});
      await db.insert('patrimony', {'name': 'Biz', 'amount_cents': 990400, 'is_debt': 0});
      await db.insert('patrimony', {'name': 'Consignado BB', 'amount_cents': 2149400, 'is_debt': 1});
    });
    return _database!;
  }

  Future<List<TransactionEntry>> transactions() async => (await (await database).query('transactions', orderBy: 'date DESC, id DESC')).map(TransactionEntry.fromMap).toList();
  Future<List<PatrimonyItem>> patrimony() async => (await (await database).query('patrimony', orderBy: 'is_debt, name')).map(PatrimonyItem.fromMap).toList();
  Future<void> addTransaction(TransactionEntry entry) async => (await database).insert('transactions', entry.toMap()..remove('id'));
  Future<void> deleteTransaction(int id) async => (await database).delete('transactions', where: 'id = ?', whereArgs: [id]);
  Future<void> addPatrimony(PatrimonyItem item) async => (await database).insert('patrimony', item.toMap()..remove('id'));
  Future<void> deletePatrimony(int id) async => (await database).delete('patrimony', where: 'id = ?', whereArgs: [id]);
}
