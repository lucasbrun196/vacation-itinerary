import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import 'storage_service.dart';

/// Seleção de arquivos que funciona igual na Web e no celular.
///
/// Na Web o plugin devolve `bytes`; no celular, um `path`. Pedindo
/// `withData: true` sempre recebemos bytes, e o upload usa `putData`
/// nos dois casos — por isso nenhuma tela precisa de `if (kIsWeb)`.
class FilePickerService {
  const FilePickerService();

  static const _imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'heic'];
  static const _receiptExtensions = [..._imageExtensions, 'pdf'];
  static const _mediaExtensions = [..._imageExtensions, 'mp4', 'mov', 'webm'];

  /// Comprovantes: foto do PIX ou PDF.
  Future<List<PickedFileData>> pickReceipts({bool allowMultiple = true}) =>
      _pick(_receiptExtensions, allowMultiple);

  Future<List<PickedFileData>> pickImages({bool allowMultiple = true}) =>
      _pick(_imageExtensions, allowMultiple);

  Future<List<PickedFileData>> pickMedia({bool allowMultiple = true}) =>
      _pick(_mediaExtensions, allowMultiple);

  Future<List<PickedFileData>> _pick(List<String> extensions, bool allowMultiple) async {
    // A API separa seleção única de múltipla; a nossa não precisa.
    final files = allowMultiple
        ? await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: extensions,
          )
        : [
            ?await FilePicker.pickFile(
              type: FileType.custom,
              allowedExtensions: extensions,
            ),
          ];

    if (files.isEmpty) return const [];

    // `readAsBytes` funciona igual nos dois mundos: na Web lê o blob,
    // no celular lê o arquivo local.
    return Future.wait(
      files.map((f) async => PickedFileData(
            bytes: await f.readAsBytes(),
            fileName: f.name,
            contentType: _contentTypeFor(_extensionOf(f.name)),
          )),
    );
  }

  static String? _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 && dot < fileName.length - 1 ? fileName.substring(dot + 1) : null;
  }

  static String _contentTypeFor(String? extension) => switch (extension?.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'heic' => 'image/heic',
        'pdf' => 'application/pdf',
        'mp4' => 'video/mp4',
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        _ => 'application/octet-stream',
      };

  /// Só para diagnóstico em log — a lógica de upload não depende disto.
  static bool get isWeb => kIsWeb;
}
