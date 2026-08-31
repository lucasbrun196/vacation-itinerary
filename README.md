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

## Mapa

Cada atividade do roteiro pode ter um ponto marcado no mapa. A coordenada
(`lat`/`lng`) fica **só no banco** — é ela que alimenta a previsão do tempo,
que precisa de posição exata e não de nome. Na tela aparece sempre o nome do
lugar: "Praia da Joaquina", "Rua Bocaiúva".

| Peça | Serviço | Plano gratuito |
|---|---|---|
| Tiles do mapa | Mapbox Raster Tiles | 750 mil requisições/mês |
| Nome ⇄ coordenada | Nominatim (OpenStreetMap) | grátis, 1 requisição/s |
| Previsão do tempo | [Open-Meteo](https://open-meteo.com) | grátis, sem chave |

### Previsão do tempo

O card da atividade ganha um chip com a máxima, a mínima e o ícone da
condição do dia. **Tocar no chip abre o painel do dia**: se vai chover e com
que chance, quanto deve cair em milímetros, sensação térmica, vento, índice
UV, nascer e pôr do sol, e a curva hora a hora — com a hora da atividade
destacada, quando ela tem horário marcado.

O chip só aparece quando as duas coisas valem:

- a atividade tem um **lugar fixado no mapa** (sem coordenada não há o que
  consultar);
- falta **no máximo uma semana** para a viagem começar, e ela ainda não
  acabou. Antes disso a previsão é chute, e um número na tela vira promessa.

A Open-Meteo não pede chave nem cadastro: nada entra no `--dart-define`. Ela
cobre 16 dias à frente, então dias mais distantes de uma viagem longa ficam
sem chip até chegarem à janela. Falha de rede não mostra erro — o chip
simplesmente não aparece. Dados de previsão por Open-Meteo.eu (CC BY 4.0).

A geocodificação **não** é a do Mapbox de propósito: o plano gratuito de lá é o
*temporary geocoding*, cujos termos não permitem guardar o resultado — e aqui o
nome do lugar é gravado no Firestore.

### Token do Mapbox

1. Criar conta em <https://account.mapbox.com> e copiar o **token público**
   (começa com `pk.`). A conta gratuita não pede cartão.
2. Rodar passando o token:

```bash
flutter run -d web-server --web-port 5173 --dart-define=MAPBOX_TOKEN=pk.SEU_TOKEN
```

3. Recomendado: em <https://account.mapbox.com/access-tokens>, restringir o
   token por **URL** (`localhost:5173` e o domínio da Vercel). O token vai
   dentro do bundle web — ele é público por natureza, e a restrição de URL é a
   proteção de verdade.

Na Vercel, criar a variável de ambiente `MAPBOX_TOKEN` e trocar o
`buildCommand` do `vercel.json` para:

```
flutter/bin/flutter build web --release --dart-define=MAPBOX_TOKEN=$MAPBOX_TOKEN
```

Sem token nada quebra: o botão "Escolher no mapa" fica desabilitado explicando
o que falta, e os campos "Lugar" e "Endereço" seguem sendo digitados à mão.

## Deploy na Vercel

O build roda por `scripts/vercel_build.sh`, que baixa o Flutter, gera as
credenciais a partir das variáveis de ambiente e compila `build/web`. O
`vercel.json` já aponta para ele.

### 1. Variáveis de ambiente do projeto na Vercel

| Variável | Onde achar |
|---|---|
| `MAPBOX_TOKEN` | <https://account.mapbox.com/access-tokens> (token público, `pk.`) |
| `FIREBASE_API_KEY` | Console do Firebase → ⚙ → Configurações do projeto → Seus apps → Web |
| `FIREBASE_APP_ID` | idem |
| `FIREBASE_MESSAGING_SENDER_ID` | idem |
| `FIREBASE_PROJECT_ID` | idem |
| `FIREBASE_AUTH_DOMAIN` | idem |
| `FIREBASE_STORAGE_BUCKET` | idem |

Os mesmos valores estão no `lib/firebase_options.dart` local. Para listar:

```bash
sed -n '/static const FirebaseOptions web/,/);/p' lib/firebase_options.dart
```

`lib/firebase_options.dart` continua fora do git: na Vercel ele é **gerado no
build**, só com o bloco web.

### 2. Autorizar o domínio no Firebase Auth

Console do Firebase → **Authentication** → **Settings** → **Domínios
autorizados** → adicionar o domínio da Vercel (`seu-app.vercel.app` e o
domínio próprio, se houver).

Sem isso o login falha com `auth/unauthorized-domain` — e o app parece quebrado
sem dizer o porquê.

### 3. Restringir o token do Mapbox

Em <https://account.mapbox.com/access-tokens>, limitar o token às URLs
`http://localhost:5173` e ao domínio da Vercel. O token vai dentro do bundle:
a restrição por URL é a proteção de verdade.

### 4. Deploy

```bash
vercel --prod
```

Ou conectar o repositório no painel da Vercel — o `vercel.json` cuida do resto.
O primeiro build demora uns minutos porque baixa o SDK do Flutter.

### Build local igual ao da Vercel

```bash
flutter build web --release --dart-define=MAPBOX_TOKEN=pk.SEU_TOKEN
```

O `flutter run` na web usa o compilador de debug e é **muito** mais lento que o
release — não julgue o desempenho do app por ele.

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
