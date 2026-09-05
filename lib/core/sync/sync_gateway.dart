import '../models/finance_models.dart';

/// Contrato para sincronização futura entre aparelhos.
/// A aplicação continua local-first quando nenhum gateway é configurado.
abstract interface class FinanceSyncGateway {
  Future<void> push(
      {required int householdId,
      required List<TransactionEntry> transactions,
      required List<PatrimonyItem> patrimony});
  Future<({List<TransactionEntry> transactions, List<PatrimonyItem> patrimony})>
      pull({required int householdId});
}

class LocalOnlySyncGateway implements FinanceSyncGateway {
  @override
  Future<void> push(
      {required int householdId,
      required List<TransactionEntry> transactions,
      required List<PatrimonyItem> patrimony}) async {}

  @override
  Future<({List<TransactionEntry> transactions, List<PatrimonyItem> patrimony})>
      pull({required int householdId}) async =>
          (transactions: <TransactionEntry>[], patrimony: <PatrimonyItem>[]);
}
