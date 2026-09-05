import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/models/finance_models.dart';
import '../core/state/finance_controller.dart';

final _money = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
String money(int c) => _money.format(c / 100);
String monthLabel(DateTime d) =>
    DateFormat('MMM/yy', 'pt_BR').format(d).replaceAll('.', '');

class MeuDinheiroApp extends StatelessWidget {
  const MeuDinheiroApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp.router(
      title: 'Meu dinheiro',
      theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b4b)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xfff5f7f6)),
      routerConfig: GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
        GoRoute(
            path: '/transactions',
            builder: (_, __) => const TransactionsScreen()),
        GoRoute(
            path: '/patrimony', builder: (_, __) => const PatrimonyScreen()),
        GoRoute(path: '/goals', builder: (_, __) => const GoalsScreen()),
        GoRoute(path: '/more', builder: (_, __) => const MoreScreen()),
        GoRoute(
            path: '/household', builder: (_, __) => const HouseholdScreen()),
        GoRoute(path: '/backup', builder: (_, __) => const BackupScreen()),
        GoRoute(path: '/controls', builder: (_, __) => const ControlsScreen())
      ]));
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<FinanceController>();
    return AppScaffold(
        title: 'Meu dinheiro',
        index: 0,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Eyebrow('CONTROLE FINANCEIRO'),
          Text('Visão geral',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const MonthSelector(),
          Row(children: [
            Expanded(child: SummaryCard('Receitas', c.income, Colors.green)),
            Expanded(child: SummaryCard('Despesas', c.expenses, Colors.orange)),
            Expanded(
                child: SummaryCard('Saldo', c.income - c.expenses, Colors.teal))
          ]),
          const SizedBox(height: 18),
          const Eyebrow('ANÁLISE DO MÊS'),
          Text('Despesas por categoria',
              style: Theme.of(context).textTheme.titleLarge),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                      height: 200,
                      child: Row(children: [
                        Expanded(child: PieChart(c)),
                        Expanded(child: CategoryBars(c))
                      ]))))
        ]));
  }
}

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<FinanceController>();
    final items = c.visibleTransactions;
    return AppScaffold(
        title: 'Fluxo',
        index: 1,
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showEntryDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Lançamento')),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const MonthSelector(),
          const Eyebrow('FILTRAR POR RESPONSÁVEL'),
          Wrap(spacing: 8, children: [
            ChoiceChip(
                label: const Text('Todos'),
                selected: c.memberFilterId == null,
                onSelected: (_) => c.filterByMember(null)),
            ...c.members.map((m) => ChoiceChip(
                label: Text(m.name),
                selected: c.memberFilterId == m.id,
                onSelected: (_) => c.filterByMember(m.id)))
          ]),
          if (items.isEmpty)
            const EmptyState('Nenhum lançamento neste mês.')
          else
            ...items.map((x) {
              final m = c.members.where((a) => a.id == x.memberId);
              return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                      x.type == EntryType.income
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      color: x.type == EntryType.income
                          ? Colors.green
                          : Colors.red),
                  title: Row(children: [
                    Expanded(child: Text(x.description)),
                    Chip(
                        label: Text(m.isEmpty ? 'Casa' : m.first.name),
                        visualDensity: VisualDensity.compact)
                  ]),
                  subtitle: Text(monthLabel(x.date)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(money(x.amountCents)),
                    IconButton(
                        onPressed: () => confirmDelete(
                            context, () => c.deleteTransaction(x.id)),
                        icon: const Icon(Icons.delete_outline))
                  ]));
            })
        ]));
  }
}

class PatrimonyScreen extends StatelessWidget {
  const PatrimonyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<FinanceController>();
    return AppScaffold(
        title: 'Patrimônio',
        index: 2,
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showPatrimonyDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Item')),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Patrimônio líquido',
              style: Theme.of(context).textTheme.titleMedium),
          Text(money(c.assets - c.debts),
              style: Theme.of(context)
                  .textTheme
                  .displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.teal)),
          Text('Evolução mês a mês',
              style: Theme.of(context).textTheme.titleLarge),
          Card(
              child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                      height: 180,
                      child: SnapshotChart(c.patrimonySnapshots)))),
          Text('Ativos — ${money(c.assets)}',
              style: Theme.of(context).textTheme.titleLarge),
          ...c.patrimony.where((x) => !x.isDebt).map((x) => PatrimonyTile(x)),
          Text('Dívidas — ${money(c.debts)}',
              style: Theme.of(context).textTheme.titleLarge),
          ...c.patrimony.where((x) => x.isDebt).map((x) => PatrimonyTile(x))
        ]));
  }
}

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<FinanceController>();
    return AppScaffold(
      title: 'Objetivos',
      index: 3,
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => showGoalDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Objetivo')),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Eyebrow('CONTA DE OBJETIVOS'),
        Text('Metas da casa',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        if (c.goals.isEmpty)
          const EmptyState('Nenhum objetivo cadastrado.')
        else
          ...c.goals.map((g) => Card(
                  child: ListTile(
                title: Text(g.name),
                subtitle: LinearProgressIndicator(
                    value: g.targetCents == 0
                        ? 0
                        : (g.savedCents / g.targetCents)
                            .clamp(0, 1)
                            .toDouble()),
                trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${money(g.savedCents)} / ${money(g.targetCents)}'),
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            onPressed: () => showContributionDialog(context, g),
                            icon: const Icon(Icons.add_circle_outline)),
                        IconButton(
                            onPressed: () => confirmDelete(
                                context, () => c.deleteGoal(g.id)),
                            icon: const Icon(Icons.delete_outline)),
                      ]),
                    ]),
              )))
      ]),
    );
  }
}

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context) => AppScaffold(
      title: 'Mais',
      index: 4,
      child: Column(children: [
        ListTile(
            leading: const Icon(Icons.group_outlined),
            title: const Text('Casa, membros, contas e categorias'),
            onTap: () => context.go('/household')),
        ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Controles do app'),
            onTap: () => context.go('/controls')),
        ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup e restauração'),
            onTap: () => context.go('/backup'))
      ]));
}

class AppScaffold extends StatelessWidget {
  const AppScaffold(
      {required this.title,
      required this.index,
      required this.child,
      this.floatingActionButton,
      super.key});
  final String title;
  final int index;
  final Widget child;
  final Widget? floatingActionButton;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: Text(title), actions: [
        IconButton(
            onPressed: () => context.go('/transactions'),
            icon: const Icon(Icons.add))
      ]),
      body: RefreshIndicator(
          onRefresh: context.read<FinanceController>().load,
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: child)),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => context
              .go(['/', '/transactions', '/patrimony', '/goals', '/more'][i]),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined), label: 'Resumo'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined), label: 'Fluxo'),
            NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                label: 'Patrimônio'),
            NavigationDestination(
                icon: Icon(Icons.flag_outlined), label: 'Objetivos'),
            NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais')
          ]));
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2)));
}

class MonthSelector extends StatelessWidget {
  const MonthSelector({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<FinanceController>();
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      IconButton(
          onPressed: () => c.selectMonth(
              DateTime(c.selectedMonth.year, c.selectedMonth.month - 1)),
          icon: const Icon(Icons.chevron_left)),
      Text(monthLabel(c.selectedMonth),
          style: const TextStyle(fontWeight: FontWeight.bold)),
      IconButton(
          onPressed: () => c.selectMonth(
              DateTime(c.selectedMonth.year, c.selectedMonth.month + 1)),
          icon: const Icon(Icons.chevron_right))
    ]);
  }
}

class SummaryCard extends StatelessWidget {
  const SummaryCard(this.label, this.value, this.color, {super.key});
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(9),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            FittedBox(
                child: Text(money(value),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15)))
          ])));
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Center(child: Text(text)));
}

class PatrimonyTile extends StatelessWidget {
  const PatrimonyTile(this.item, {super.key});
  final PatrimonyItem item;
  @override
  Widget build(BuildContext context) {
    final c = context.read<FinanceController>();
    return ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(item.name),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(money(item.amountCents)),
          IconButton(
              onPressed: () =>
                  confirmDelete(context, () => c.deletePatrimony(item.id)),
              icon: const Icon(Icons.delete_outline))
        ]));
  }
}

class PieChart extends StatelessWidget {
  const PieChart(this.c, {super.key});
  final FinanceController c;
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: PiePainter(c.categoryTotals.values.toList()),
      child:
          Center(child: Text(money(c.expenses), textAlign: TextAlign.center)));
}

class CategoryBars extends StatelessWidget {
  const CategoryBars(this.c, {super.key});
  final FinanceController c;
  @override
  Widget build(BuildContext context) {
    final v = c.categoryTotals;
    final max = v.values.fold<int>(0, (a, b) => a > b ? a : b);
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: v.entries
            .take(5)
            .map((e) => Row(children: [
                  SizedBox(
                      width: 60,
                      child: Text(e.key,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 9))),
                  Expanded(
                      child: LinearProgressIndicator(
                          value: max == 0 ? 0 : e.value / max)),
                  Text(money(e.value), style: const TextStyle(fontSize: 8))
                ]))
            .toList());
  }
}

class PiePainter extends CustomPainter {
  PiePainter(this.v);
  final List<int> v;
  @override
  void paint(Canvas c, Size s) {
    final t = v.fold<int>(0, (a, b) => a + b);
    if (t == 0) return;
    var start = -1.57;
    final colors = [
      Colors.teal,
      Colors.orange,
      Colors.blue,
      Colors.purple,
      Colors.red
    ];
    for (var i = 0; i < v.length; i++) {
      final sweep = v[i] / t * 6.283;
      c.drawArc(Offset.zero & s, start, sweep, true,
          Paint()..color = colors[i % colors.length]);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant PiePainter old) => old.v != v;
}

class SnapshotChart extends StatelessWidget {
  const SnapshotChart(this.items, {super.key});
  final List<PatrimonySnapshot> items;
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: SnapshotPainter(items), child: const SizedBox.expand());
}

class SnapshotPainter extends CustomPainter {
  SnapshotPainter(this.items);
  final List<PatrimonySnapshot> items;
  @override
  void paint(Canvas c, Size s) {
    if (items.isEmpty) return;
    final max = items
        .map((x) => x.amountCents)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final min = items
        .map((x) => x.amountCents)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
    final p = Path();
    for (var i = 0; i < items.length; i++) {
      final x =
          items.length == 1 ? s.width / 2 : i * s.width / (items.length - 1);
      final y = s.height -
          ((items[i].amountCents - min) /
              (max - min == 0 ? 1 : max - min) *
              (s.height - 20)) -
          10;
      i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
    }
    c.drawPath(
        p,
        Paint()
          ..color = Colors.teal
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant SnapshotPainter old) => old.items != items;
}

Future<void> confirmDelete(BuildContext context, VoidCallback action) async {
  final ok = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(title: const Text('Excluir registro?'), actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir'))
          ]));
  if (ok == true) action();
}

Future<void> showEntryDialog(BuildContext context) async {
  final c = context.read<FinanceController>();
  final n = TextEditingController(), v = TextEditingController();
  var type = EntryType.expense;
  var member = c.members.first.id, account = c.accounts.first.id;
  int? category;
  await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, set) => AlertDialog(
                  title: const Text('Novo lançamento'),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    DropdownButtonFormField<EntryType>(
                        initialValue: type,
                        items: const [
                          DropdownMenuItem(
                              value: EntryType.expense, child: Text('Despesa')),
                          DropdownMenuItem(
                              value: EntryType.income, child: Text('Receita'))
                        ],
                        onChanged: (x) => set(() {
                              type = x!;
                              category = null;
                            }),
                        decoration: const InputDecoration(labelText: 'Tipo')),
                    TextField(
                        controller: n,
                        decoration:
                            const InputDecoration(labelText: 'Descrição')),
                    TextField(
                        controller: v,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Valor em centavos')),
                    DropdownButtonFormField<int>(
                        initialValue: member,
                        items: c.members
                            .map((x) => DropdownMenuItem(
                                value: x.id, child: Text(x.name)))
                            .toList(),
                        onChanged: (x) => set(() => member = x!),
                        decoration:
                            const InputDecoration(labelText: 'Responsável')),
                    DropdownButtonFormField<int>(
                        initialValue: account,
                        items: c.accounts
                            .map((x) => DropdownMenuItem(
                                value: x.id, child: Text(x.name)))
                            .toList(),
                        onChanged: (x) => set(() => account = x!),
                        decoration: const InputDecoration(labelText: 'Conta')),
                    DropdownButtonFormField<int?>(
                        initialValue: category,
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Sem categoria')),
                          ...c.categories.where((x) => x.type == type).map(
                              (x) => DropdownMenuItem(
                                  value: x.id, child: Text(x.name)))
                        ],
                        onChanged: (x) => set(() => category = x),
                        decoration:
                            const InputDecoration(labelText: 'Categoria'))
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () async {
                          final cents = int.tryParse(v.text);
                          if (n.text.trim().isEmpty ||
                              cents == null ||
                              cents <= 0) return;
                          await c.addDetailedTransaction(
                              type: type,
                              description: n.text.trim(),
                              amountCents: cents,
                              memberId: member,
                              accountId: account,
                              categoryId: category,
                              status: 'paid');
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Salvar'))
                  ])));
}

Future<void> showGoalDialog(BuildContext context) async {
  final n = TextEditingController(), v = TextEditingController();
  await showDialog(
      context: context,
      builder: (_) => AlertDialog(
              title: const Text('Novo objetivo'),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: n,
                    decoration: const InputDecoration(labelText: 'Nome')),
                TextField(
                    controller: v,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Valor alvo em centavos'))
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () async {
                      final x = int.tryParse(v.text);
                      if (n.text.trim().isEmpty || x == null || x <= 0) return;
                      await context
                          .read<FinanceController>()
                          .addGoal(name: n.text.trim(), targetCents: x);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Salvar'))
              ]));
}

Future<void> showContributionDialog(BuildContext context, Goal g) async {
  final v = TextEditingController();
  await showDialog(
      context: context,
      builder: (_) => AlertDialog(
              title: Text('Saldo para ${g.name}'),
              content: TextField(
                  controller: v,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Valor em centavos')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () async {
                      final x = int.tryParse(v.text);
                      if (x == null || x <= 0) return;
                      await context
                          .read<FinanceController>()
                          .addGoalContribution(g.id, x);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Adicionar'))
              ]));
}

Future<void> showPatrimonyDialog(BuildContext context) async {
  final n = TextEditingController(), v = TextEditingController();
  var debt = false;
  await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, set) => AlertDialog(
                  title: const Text('Novo item patrimonial'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: n,
                        decoration: const InputDecoration(labelText: 'Nome')),
                    TextField(
                        controller: v,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Valor em centavos')),
                    SwitchListTile(
                        value: debt,
                        onChanged: (x) => set(() => debt = x),
                        title: const Text('É uma dívida?'))
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () async {
                          final x = int.tryParse(v.text);
                          if (n.text.trim().isEmpty || x == null || x <= 0)
                            return;
                          await context.read<FinanceController>().addPatrimony(
                              name: n.text.trim(),
                              amountCents: x,
                              isDebt: debt);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Salvar'))
                  ])));
}

class HouseholdScreen extends StatelessWidget {
  const HouseholdScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final c = context.watch<FinanceController>();
    return AppScaffold(
        title: 'Nossa casa',
        index: 4,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Eyebrow('MEMBROS'),
          ...c.members.map((m) => ListTile(
              title: Text(m.name),
              trailing: IconButton(
                  onPressed: () =>
                      confirmDelete(context, () => c.deleteMember(m.id)),
                  icon: const Icon(Icons.delete_outline)))),
          FilledButton(
              onPressed: () =>
                  showTextDialog(context, 'Novo membro', c.addMember),
              child: const Text('Adicionar membro')),
          const Eyebrow('CONTAS E CARTÕES'),
          ...c.accounts.map((a) => ListTile(
              title: Text(a.name),
              subtitle: Text(a.kind),
              trailing: IconButton(
                  onPressed: () =>
                      confirmDelete(context, () => c.deleteAccount(a.id)),
                  icon: const Icon(Icons.delete_outline)))),
          FilledButton(
              onPressed: () => showAccountDialog(context),
              child: const Text('Adicionar conta/cartão')),
          const Eyebrow('CATEGORIAS'),
          Wrap(
              spacing: 5,
              children: c.categories
                  .map((x) => InputChip(
                      label: Text(x.name),
                      onDeleted: () =>
                          confirmDelete(context, () => c.deleteCategory(x.id))))
                  .toList()),
          FilledButton(
              onPressed: () => showCategoryDialog(context),
              child: const Text('Adicionar categoria')),
        ]));
  }
}

Future<void> showTextDialog(BuildContext context, String title,
    Future<void> Function(String) save) async {
  final x = TextEditingController();
  await showDialog(
      context: context,
      builder: (_) => AlertDialog(
              title: Text(title),
              content: TextField(
                  controller: x,
                  decoration: const InputDecoration(labelText: 'Nome')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () async {
                      if (x.text.trim().isEmpty) return;
                      await save(x.text.trim());
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Salvar'))
              ]));
}

Future<void> showAccountDialog(BuildContext context) async {
  final n = TextEditingController();
  var kind = 'bank';
  await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, set) => AlertDialog(
                  title: const Text('Nova conta/cartão'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: n,
                        decoration: const InputDecoration(labelText: 'Nome')),
                    DropdownButtonFormField<String>(
                        initialValue: kind,
                        items: const [
                          DropdownMenuItem(
                              value: 'bank', child: Text('Conta bancária')),
                          DropdownMenuItem(
                              value: 'credit_card',
                              child: Text('Cartão de crédito')),
                          DropdownMenuItem(
                              value: 'cash', child: Text('Dinheiro físico'))
                        ],
                        onChanged: (x) => set(() => kind = x!),
                        decoration: const InputDecoration(labelText: 'Tipo'))
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () async {
                          if (n.text.trim().isEmpty) return;
                          await context
                              .read<FinanceController>()
                              .addAccount(name: n.text.trim(), kind: kind);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Salvar'))
                  ])));
}

Future<void> showCategoryDialog(BuildContext context) async {
  final n = TextEditingController();
  var type = EntryType.expense;
  await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, set) => AlertDialog(
                  title: const Text('Nova categoria'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: n,
                        decoration: const InputDecoration(labelText: 'Nome')),
                    DropdownButtonFormField<EntryType>(
                        initialValue: type,
                        items: const [
                          DropdownMenuItem(
                              value: EntryType.expense, child: Text('Despesa')),
                          DropdownMenuItem(
                              value: EntryType.income, child: Text('Receita'))
                        ],
                        onChanged: (x) => set(() => type = x!),
                        decoration: const InputDecoration(labelText: 'Tipo'))
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () async {
                          if (n.text.trim().isEmpty) return;
                          await context
                              .read<FinanceController>()
                              .addCategory(name: n.text.trim(), type: type);
                          if (context.mounted) Navigator.pop(context);
                        },
                        child: const Text('Salvar'))
                  ])));
}

class ControlsScreen extends StatefulWidget {
  const ControlsScreen({super.key});
  @override
  State<ControlsScreen> createState() => _ControlsState();
}

class _ControlsState extends State<ControlsScreen> {
  bool hide = false, compact = false;
  double scale = 1;
  @override
  Widget build(BuildContext context) => AppScaffold(
        title: 'Controles do app',
        index: 4,
        child: Column(children: [
          SwitchListTile(
              title: const Text('Ocultar valores'),
              value: hide,
              onChanged: (v) => setState(() => hide = v)),
          SwitchListTile(
              title: const Text('Modo compacto'),
              value: compact,
              onChanged: (v) => setState(() => compact = v)),
          ListTile(
              title: const Text('Tamanho do texto'),
              subtitle: Slider(
                  value: scale,
                  min: .85,
                  max: 1.25,
                  divisions: 8,
                  onChanged: (v) => setState(() => scale = v))),
        ]),
      );
}

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});
  @override
  Widget build(BuildContext context) => const MoreScreen();
}

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});
  @override
  Widget build(BuildContext context) => AppScaffold(
      title: 'Backup',
      index: 4,
      child: Column(children: [
        FilledButton(
            onPressed: () => exportBackup(context),
            child: const Text('Exportar dados')),
        OutlinedButton(
            onPressed: () => importBackup(context),
            child: const Text('Importar dados'))
      ]));
}

Future<void> exportBackup(BuildContext context) async {
  final json = await context.read<FinanceController>().exportJson();
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/meu-dinheiro-backup.json');
  await file.writeAsString(json);
  await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: 'Backup do Meu Dinheiro'));
}

Future<void> importBackup(BuildContext context) async {
  final r = await FilePicker.platform.pickFiles(
      type: FileType.custom, allowedExtensions: ['json'], withData: true);
  if (r == null) return;
  final f = r.files.single;
  final Uint8List? b =
      f.bytes ?? (f.path == null ? null : await File(f.path!).readAsBytes());
  if (b != null)
    await context.read<FinanceController>().importJson(utf8.decode(b));
}
