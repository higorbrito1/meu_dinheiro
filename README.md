# Meu Dinheiro — Flutter

Reescrita do aplicativo financeiro em Flutter, com arquitetura local-first.

## Princípios

- UI separada da regra de negócio e persistência.
- Valores financeiros armazenados em centavos (`int`).
- SQLite como fonte única dos lançamentos e patrimônio.
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

## Próximas etapas

1. Implementar exportação/importação JSON versionada.
2. Migrar os dados iniciais do app Expo.
3. Adicionar categorias e contas.
4. Expandir relatórios por período.
5. Criar testes de widget e integração.
