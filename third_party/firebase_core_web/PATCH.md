# Patch local do firebase_core_web 3.11.0

## Por que isto existe

O Dart 3.11 restringiu a extensão `isA` de `dart:js_interop`: ela só se aplica
a `JSAny?`, e não mais ao `Object` que vem de um `catch (e)`. O
`firebase_core_web` 3.11.0 (versão mais recente no pub.dev nesta data) ainda
usa o padrão antigo em dois pontos, o que quebra **qualquer** compilação
Flutter Web que dependa do Firebase.

    lib/src/firebase_core_web.dart:397  if (!e.isA<JSObject>()) {
    lib/src/firebase_core_web.dart:448  if (!e.isA<JSObject>()) {

## O que foi alterado

Apenas essas duas linhas, com um cast explícito:

    if (!(e as JSAny?).isA<JSObject>()) {

Nenhuma outra mudança. Os demais pacotes do FlutterFire
(cloud_firestore_web, firebase_auth_web, firebase_storage_web) não usam esse
padrão e estão intactos.

## Como remover

Assim que o FlutterFire publicar uma versão corrigida:

1. Apague a seção `dependency_overrides` do `pubspec.yaml`.
2. Apague a pasta `third_party/`.
3. `flutter pub get`
