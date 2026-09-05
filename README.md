# Meu Dinheiro — Flutter

Reescrita do aplicativo financeiro em Flutter, com arquitetura local-first.

## Princípios

- UI separada da regra de negócio e persistência.
- Valores financeiros armazenados em centavos (`int`).
- SQLite como fonte única dos lançamentos e patrimônio.
- Estrutura de casa compartilhada com membros, contas e categorias.
- Lançamentos preparados para responsável, conta, status e observações.
- Tabelas preparadas para recorrências, orçamentos e metas.
- Navegação declarativa com `go_router`.
- Estado da aplicação isolado em `FinanceController`.
- Testes automatizados em `test/`.

## Executar

Com o Flutter instalado:

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Estado atual

A base local já suporta uma casa com dois membros (`Você` e `Esposa`), conta principal, categorias e migração do esquema inicial. Os lançamentos continuam sendo apresentados nas telas existentes, enquanto os novos campos já estão prontos no banco.

## Próximas etapas

1. Expor no formulário a seleção de membro, conta e categoria.
2. Implementar exportação/importação JSON versionada.
3. Implementar recorrências, orçamentos e metas na interface.
4. Expandir relatórios por período e por membro.
5. Criar autenticação e backend para sincronização entre celulares.
6. Criar testes de widget e integração.
