# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

App de viagem compartilhada em Flutter (Web primeiro, depois Android/iOS) com
Firebase. O `README.md` cobre o produto — permissões, modelo de contas, deploy.
Este arquivo cobre o que faz errar.

O código, os comentários e a documentação são em **português**. O histórico do
git é em **inglês** — ver `.claude/skills/commit/SKILL.md`.

## Comandos

```bash
flutter run -d web-server --web-port 5173   # a porta usada por .claude/launch.json
flutter analyze                             # precisa ficar sem nenhum aviso
flutter test
flutter test test/bill_split_test.dart --plain-name 'cada pessoa paga'
firebase deploy --only firestore:rules,firestore:indexes,storage
```

## Como um dado chega na tela

`FirestoreRefs` → repositório → provider → widget.

- **`lib/data/services/firestore_refs.dart`** guarda todos os caminhos do
  Firestore. Tudo mora sob `trips/{tripId}`, o que mantém as regras simples e
  permite apagar uma viagem inteira. Nenhum outro arquivo monta caminho na mão.
- **`lib/data/repositories/`** fala com o Firebase e devolve modelos. Widget
  nenhum toca em `DocumentSnapshot`.
- **`lib/app/providers.dart`** é o índice de tudo que as telas leem.

Regra de dependência: `features` usa `shared`, `data` e `core`; `shared` usa só
`core`; `core` não depende de ninguém.

## Armadilhas

Cada uma destas já custou uma sessão de depuração.

**`currentTripIdProvider` lança por padrão.** Ele é sobrescrito por um
`ProviderScope` dentro da casca da viagem. Todo provider que o consome — direta
ou indiretamente — precisa declarar `dependencies: [...]`, senão o Riverpod
recusa a leitura dentro do escopo com "Tried to read a provider from a place
where one of its dependencies were overridden".

**Formulários só abrem por `showAppSheet`** (`lib/shared/widgets/layout/app_sheet.dart`).
Diálogos e bottom sheets são montados no overlay do Navigator raiz, **fora** do
escopo da viagem; `showAppSheet` reembrulha o `ProviderContainer` de quem abriu.
Chamar `showDialog` direto dentro de uma viagem quebra na hora de salvar.

**Dinheiro é sempre `int` de centavos.** `double` não fecha 9000/6/4. Converter
para texto só na exibição, via `Money.format`. `Money.divide` distribui o resto
um centavo por vez, então a soma bate exatamente com o total.

**O valor da parcela é derivado, nunca guardado.** Sai de
`Bill.effectiveInstallmentCents`, a partir do total, do número de parcelas e do
número de pessoas. Guardar o valor arredondado e recalcular o total a partir
dele foi o que fez R$ 9.950,00 virar R$ 9.950,04. Não existe conceito de juros.

**Ids de cota são determinísticos**: `'{parcela}_{uid}'`. É o que preserva o
pagamento, o comprovante e a marcação de pago quando a conta é editada.

**Nas regras do Firestore, `delete` fica separado de `create, update`.** Em uma
exclusão o `request.resource` é nulo, então qualquer validação que olhe os
campos do documento nega a operação em silêncio — a UI parece funcionar e o
documento continua lá.

**`collectionGroup('shares')` precisa de duas coisas:** uma regra própria
(`match /{path=**}/shares/{shareId}`, porque as regras aninhadas não a
autorizam) e o filtro por `tripId`, sem o qual a consulta atravessa as viagens
de outras pessoas. Ver `FirestoreRefs.sharesOfTrip`.

**Rotas usam `ShellRoute`, não `StatefulShellRoute`** — este último não aceita
raiz de branch parametrizada, e todas as rotas internas são
`/viagem/:tripId/...`.

**`third_party/firebase_core_web` é uma cópia com patch de duas linhas**, ligada
por `dependency_overrides`, porque a versão publicada não compila no Dart 3.11.
Está excluída do analisador. Remover quando o FlutterFire publicar uma versão
compatível — instruções em `third_party/firebase_core_web/PATCH.md`.

## Convenções de UI

- Espaçamento e raio saem de `Gap` e `Radii` (`lib/core/theme/app_tokens.dart`),
  nunca números soltos. `Gap.vMd` é um `SizedBox` pronto.
- `lib/core/extensions/context_ext.dart` dá `context.text`, `context.colors`,
  `context.isMobile`, `context.reduceMotion`.
- `AppDestination` (`lib/app/destinations.dart`) é a fonte única da navegação:
  alimenta a barra inferior, o rail e a sidebar de uma vez.
- O corte entre bottom sheet e diálogo é 700px (`Breakpoints.tablet`).
- Campo com borda contornada desenha o label flutuante **acima** da caixa: a
  área rolável de um formulário precisa de padding superior, ou o label é
  cortado.

## Credenciais

`lib/firebase_options.dart`, `android/app/google-services.json` e
`ios/Runner/GoogleService-Info.plist` estão no `.gitignore`. Gere os seus com
`flutterfire configure`, ou copie `lib/firebase_options.dart.example`.
