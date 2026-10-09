import 'dart:async';

/// O que o Firestore conta sobre um snapshot: se ele veio do cache e se
/// existe escrita local esperando o servidor.
///
/// É o `SnapshotMetadata` do Firestore reduzido ao que interessa, para
/// que a derivação do estado possa ser testada sem Firebase.
class SyncMetadata {
  const SyncMetadata({required this.isFromCache, required this.hasPendingWrites});

  final bool isFromCache;
  final bool hasPendingWrites;
}

/// Como está a conversa com o servidor, do ponto de vista de quem usa.
enum SyncStatus {
  /// Em dia com o servidor. É o estado em que nada é mostrado na tela.
  online,

  /// Tem alteração feita aqui que o servidor ainda não confirmou.
  pending,

  /// Sem rede: o que está na tela veio do cache.
  offline,
}

/// Traduz o metadado dos snapshots do Firestore em um estado só.
///
/// Existe porque o Firestore não expõe "estou online?" — o que ele
/// expõe é, a cada snapshot, de onde o dado veio. Ligar o aviso de
/// offline direto nesse sinal faria o aviso piscar em toda abertura
/// com rede, porque o primeiro snapshot vem do cache mesmo online;
/// daí a carência de [grace].
class SyncStatusService {
  const SyncStatusService({this.grace = const Duration(seconds: 3)});

  /// Quanto tempo o dado precisa seguir vindo do cache antes de isso
  /// ser tratado como falta de rede.
  final Duration grace;

  /// A regra, sem o tempo: escrita pendente é o sinal mais forte, porque
  /// é alteração de quem está ali e ainda não subiu.
  static SyncStatus statusOf(SyncMetadata meta) {
    if (meta.hasPendingWrites) return SyncStatus.pending;
    return meta.isFromCache ? SyncStatus.offline : SyncStatus.online;
  }

  /// Acompanha [source] e emite o estado só quando ele muda.
  ///
  /// `online` e `pending` saem na hora; `offline` espera [grace]
  /// confirmando que o cache não foi só o primeiro snapshot.
  Stream<SyncStatus> watch(Stream<SyncMetadata> source) {
    late StreamController<SyncStatus> out;
    StreamSubscription<SyncMetadata>? sub;
    Timer? waitingOffline;
    SyncStatus? emitted;

    void emit(SyncStatus status) {
      if (status == emitted) return;
      emitted = status;
      out.add(status);
    }

    out = StreamController<SyncStatus>(
      onListen: () {
        sub = source.listen(
          (meta) {
            // Qualquer snapshot novo invalida a espera anterior: a
            // resposta do servidor chegando é o que desarma o aviso.
            waitingOffline?.cancel();
            waitingOffline = null;

            final status = statusOf(meta);
            if (status == SyncStatus.offline) {
              waitingOffline = Timer(grace, () => emit(SyncStatus.offline));
            } else {
              emit(status);
            }
          },
          onError: out.addError,
          onDone: out.close,
        );
      },
      onCancel: () async {
        waitingOffline?.cancel();
        await sub?.cancel();
      },
    );

    return out.stream;
  }
}
