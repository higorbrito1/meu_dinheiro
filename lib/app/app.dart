import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/models/finance_models.dart';
import '../core/state/finance_controller.dart';

final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
String money(int cents) => _money.format(cents / 100);

class MeuDinheiroApp extends StatelessWidget {
  const MeuDinheiroApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Meu dinheiro',
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b4b)), useMaterial3: true, scaffoldBackgroundColor: const Color(0xfff5f7f6)),
        routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, __) => const HomeScreen()), GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()), GoRoute(path: '/patrimony', builder: (_, __) => const PatrimonyScreen()), GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()), GoRoute(path: '/backup', builder: (_, __) => const BackupScreen())]),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<FinanceController>();
    return AppScaffold(title: 'Meu dinheiro', index: 0, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Eyebrow('CONTROLE FINANCEIRO'),
      Text('Visão geral', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 18),
      Wrap(spacing: 10, runSpacing: 10, children: [SummaryCard('Receitas', c.income, Colors.green), SummaryCard('Despesas', c.expenses, Colors.orange), SummaryCard('Saldo', c.income - c.expenses, Colors.teal)]),
      const SizedBox(height: 24),
      const Eyebrow('LANÇAMENTOS RECENTES'),
      if (c.transactions.isEmpty) const EmptyState('Nenhum lançamento ainda.') else ...c.transactions.take(5).map((x) => ListTile(contentPadding: EdgeInsets.zero, leading: CircleAvatar(child: Icon(x.type == EntryType.income ? Icons.arrow_downward : Icons.arrow_upward)), title: Text(x.description), subtitle: Text(DateFormat('dd/MM/yyyy').format(x.date)), trailing: Text(money(x.amountCents), style: TextStyle(color: x.type == EntryType.income ? Colors.green : Colors.red, fontWeight: FontWeight.bold)))),
    ]));
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});
  @override
  Widget build(BuildContext context) { final c = context.watch<FinanceController>(); return AppScaffold(title: 'Fluxo', index: 1, floatingActionButton: FloatingActionButton.extended(onPressed: () => showEntryDialog(context), icon: const Icon(Icons.add), label: const Text('Lançamento')), child: c.transactions.isEmpty ? const EmptyState('Nenhum lançamento cadastrado.') : ListView.separated(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: c.transactions.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, i) { final x = c.transactions[i]; return ListTile(title: Text(x.description), subtitle: Text(DateFormat('dd/MM/yyyy').format(x.date)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(money(x.amountCents), style: TextStyle(color: x.type == EntryType.income ? Colors.green : Colors.red, fontWeight: FontWeight.bold)), IconButton(onPressed: () => confirmDelete(context, () => c.deleteTransaction(x.id)), icon: const Icon(Icons.delete_outline))])); })); }
}

class PatrimonyScreen extends StatelessWidget {
  const PatrimonyScreen({super.key});
  @override
  Widget build(BuildContext context) { final c = context.watch<FinanceController>(); return AppScaffold(title: 'Patrimônio', index: 2, floatingActionButton: FloatingActionButton.extended(onPressed: () => showPatrimonyDialog(context), icon: const Icon(Icons.add), label: const Text('Item')), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Patrimônio líquido', style: Theme.of(context).textTheme.titleMedium), Text(money(c.assets - c.debts), style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal)), const SizedBox(height: 20), Text('Ativos — ${money(c.assets)}', style: Theme.of(context).textTheme.titleLarge), ...c.patrimony.where((x) => !x.isDebt).map((x) => PatrimonyTile(x)), const SizedBox(height: 20), Text('Dívidas — ${money(c.debts)}', style: Theme.of(context).textTheme.titleLarge), ...c.patrimony.where((x) => x.isDebt).map((x) => PatrimonyTile(x))])); }
}

class ReportsScreen extends StatelessWidget { const ReportsScreen({super.key}); @override Widget build(BuildContext context) { final c = context.watch<FinanceController>(); return AppScaffold(title: 'Análises', index: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Eyebrow('RESUMO'), Text('Distribuição atual', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)), const SizedBox(height: 18), LinearProgressIndicator(value: c.income == 0 ? 0 : (c.expenses / c.income).clamp(0, 1).toDouble(), minHeight: 14), const SizedBox(height: 8), Text('${money(c.expenses)} gastos de ${money(c.income)} recebidos'), const SizedBox(height: 28), const Text('Este relatório será expandido com categorias e comparativo mensal.') ])); } }
class BackupScreen extends StatelessWidget { const BackupScreen({super.key}); @override Widget build(BuildContext context) => AppScaffold(title: 'Backup', index: 4, child: Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Eyebrow('SEGURANÇA DOS DADOS'), Text('Backup financeiro', style: Theme.of(context).textTheme.headlineSmall), const SizedBox(height: 8), const Text('A exportação JSON versionada será adicionada nesta etapa.'), const SizedBox(height: 18), FilledButton.icon(onPressed: null, icon: const Icon(Icons.upload_file), label: const Text('Exportar dados')), const SizedBox(height: 8), OutlinedButton.icon(onPressed: null, icon: const Icon(Icons.file_open), label: const Text('Importar dados'))])))); }

class AppScaffold extends StatelessWidget { const AppScaffold({required this.title, required this.index, required this.child, this.floatingActionButton, super.key}); final String title; final int index; final Widget child; final Widget? floatingActionButton; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title), actions: [IconButton(onPressed: () => context.go('/transactions'), icon: const Icon(Icons.add))]), body: RefreshIndicator(onRefresh: context.read<FinanceController>().load, child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), child: child)), floatingActionButton: floatingActionButton, bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (i) => context.go(['/', '/transactions', '/patrimony', '/reports', '/backup'][i]), destinations: const [NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Resumo'), NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Fluxo'), NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Patrimônio'), NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Análises'), NavigationDestination(icon: Icon(Icons.backup_outlined), label: 'Backup')])); }

class Eyebrow extends StatelessWidget { const Eyebrow(this.text, {super.key}); final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2))); }
class SummaryCard extends StatelessWidget { const SummaryCard(this.label, this.value, this.color, {super.key}); final String label; final int value; final Color color; @override Widget build(BuildContext context) => SizedBox(width: 150, child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label), const SizedBox(height: 8), Text(money(value), style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18))])))); }
class EmptyState extends StatelessWidget { const EmptyState(this.text, {super.key}); final String text; @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Center(child: Text(text))); }
class PatrimonyTile extends StatelessWidget { const PatrimonyTile(this.item, {super.key}); final PatrimonyItem item; @override Widget build(BuildContext context) { final c = context.read<FinanceController>(); return ListTile(contentPadding: EdgeInsets.zero, title: Text(item.name), trailing: Row(mainAxisSize: MainAxisSize.min, children: [Text(money(item.amountCents)), IconButton(onPressed: () => confirmDelete(context, () => c.deletePatrimony(item.id)), icon: const Icon(Icons.delete_outline))])); } }

Future<void> confirmDelete(BuildContext context, VoidCallback action) async { final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Excluir registro?'), content: const Text('Esta ação não pode ser desfeita.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir'))])); if (ok == true) action(); }
Future<void> showEntryDialog(BuildContext context) async { final name = TextEditingController(); final value = TextEditingController(); var type = EntryType.expense; await showDialog(context: context, builder: (_) => StatefulBuilder(builder: (context, setState) => AlertDialog(title: const Text('Novo lançamento'), content: Column(mainAxisSize: MainAxisSize.min, children: [DropdownButtonFormField(value: type, items: const [DropdownMenuItem(value: EntryType.expense, child: Text('Despesa')), DropdownMenuItem(value: EntryType.income, child: Text('Receita'))], onChanged: (v) => setState(() => type = v!), decoration: const InputDecoration(labelText: 'Tipo')), TextField(controller: name, decoration: const InputDecoration(labelText: 'Descrição')), TextField(controller: value, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor em centavos'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () async { final cents = int.tryParse(value.text); if (name.text.trim().isEmpty || cents == null || cents <= 0) return; await context.read<FinanceController>().addTransaction(type: type, description: name.text.trim(), amountCents: cents); if (context.mounted) Navigator.pop(context); }, child: const Text('Salvar'))]))); }
Future<void> showPatrimonyDialog(BuildContext context) async { final name = TextEditingController(); final value = TextEditingController(); var debt = false; await showDialog(context: context, builder: (_) => StatefulBuilder(builder: (context, setState) => AlertDialog(title: const Text('Novo item patrimonial'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome')), TextField(controller: value, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor em centavos')), SwitchListTile(value: debt, onChanged: (v) => setState(() => debt = v), title: const Text('É uma dívida?'))]), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')), FilledButton(onPressed: () async { final cents = int.tryParse(value.text); if (name.text.trim().isEmpty || cents == null || cents <= 0) return; await context.read<FinanceController>().addPatrimony(name: name.text.trim(), amountCents: cents, isDebt: debt); if (context.mounted) Navigator.pop(context); }, child: const Text('Salvar'))]))); }
