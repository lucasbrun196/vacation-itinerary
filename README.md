# Viagem 🏝️

Aplicativo de viagem compartilhada: roteiro, gastos, comprovantes e mural de
fotos em um só lugar. Flutter para Web (Vercel) e Android/iOS a partir da
mesma base de código.

## Rodando localmente

```bash
flutter pub get
flutter run -d chrome
```

Ou usando o servidor de desenvolvimento na porta 5173:

```bash
flutter run -d web-server --web-port 5173
```

## Estrutura

```
lib/
├── app/          Router, tema da aplicação e destinos de navegação
├── core/         Design system, responsividade, formatadores, extensões
├── data/         Models, repositories e services do Firebase
├── features/     Uma pasta por funcionalidade (screens/widgets/controllers)
└── shared/       Widgets reutilizáveis entre features
```

Regra de dependência: `features` usa `shared`, `data` e `core`.
`shared` usa apenas `core`. `core` não depende de ninguém.

## Autenticação e acesso

Entrar é só por **e-mail e senha do Firebase Auth** — não há acesso anônimo
nem convidado.

| Ação | Quem pode |
|---|---|
| Criar viagem | Qualquer pessoa com conta (vira admin dela) |
| Gerenciar roteiro, contas, cotas, mural | Todo participante, sem restrição |
| Adicionar / remover participantes | Só o admin |
| Excluir a viagem | Só o admin |
| Sair da viagem | Qualquer participante |

Participantes são adicionados **pelo e-mail**, e a pessoa precisa já ter
conta. O SDK cliente do Firebase Auth não permite buscar alguém por
e-mail, então cada conta é espelhada em `users/{uid}` no login — é essa
coleção que a busca consulta.

## Firebase

Os arquivos de configuração ficam em `firebase/`:

| Arquivo | Conteúdo |
|---|---|
| `firestore.rules` | Regras de acesso ao banco, baseadas em participação na viagem |
| `firestore.indexes.json` | Índices compostos necessários para as queries |
| `storage.rules` | Regras de arquivos, com limites de tipo e tamanho |

Publicar as regras:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage
```

### Gerar as credenciais

```bash
flutterfire configure
```

Isso cria `lib/firebase_options.dart`, `android/app/google-services.json`
e `ios/Runner/GoogleService-Info.plist`. **Os três estão no `.gitignore`** —
cada pessoa gera os seus apontando para o próprio projeto Firebase. Há um
modelo em `lib/firebase_options.dart.example` para quem preferir preencher
à mão.

Essas chaves identificam o app, não autorizam nada sozinhas: a proteção
real são as Security Rules em `firebase/`.

## Deploy na Vercel

`vercel.json` já está configurado com o rewrite de SPA. O build gera
`build/web`:

```bash
flutter build web --release
```

## Correção temporária de dependência

`third_party/firebase_core_web` é uma cópia local com um patch de duas
linhas — veja `third_party/firebase_core_web/PATCH.md`. Deve ser removida
quando o FlutterFire publicar uma versão compatível com o Dart 3.11.

## Modelo de contas

Uma **conta** (`bills`) cobre os dois comportamentos reais de uma viagem:

| Tipo | Comportamento | Exemplo |
|---|---|---|
| `fixed` | Total conhecido, pode ser parcelada | Aluguel do Airbnb em 6x |
| `accumulating` | Soma lançamentos, divide no fechamento | Gasolina |

Cada conta gera **cotas** (`shares`): uma por pessoa por parcela. É a
unidade que carrega valor, vencimento, marcação de pago e comprovante
do PIX. Ids determinísticos (`parcela_pessoa`) preservam os pagamentos
quando a conta é editada.

Valores são guardados em **centavos inteiros**. `double` acumula erro em
divisões e conta entre amigos precisa fechar no centavo — ver
`lib/core/utils/money.dart` e os testes em `test/bill_split_test.dart`.

## Etapas

- [x] **1** — Estrutura base, design system, navegação responsiva
- [x] **2** — Firebase conectado, autenticação, multi-viagem, participantes
- [x] **3** — Roteiro (timeline por dia, transporte, vínculo com contas)
- [x] **4** — Contas compartilhadas (parcelamento, divisão, cotas, pagamentos)
- [x] **5** — Comprovantes (upload, visualização, exclusão)
- [ ] **6** — Mural (fotos e vídeos)
- [ ] **7** — Dashboard completo, polimento e PWA
- [ ] **8** — Deploy na Vercel
- [ ] **9** — Android (APK) e iOS
