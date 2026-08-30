import 'package:cloud_firestore/cloud_firestore.dart';

/// Arquivo guardado no Storage, com os metadados no Firestore.
/// Serve tanto para comprovante de gasto quanto para comprovante de PIX.
class Attachment {
  const Attachment({
    required this.id,
    required this.fileName,
    required this.url,
    required this.storagePath,
    required this.contentType,
    required this.sizeBytes,
    required this.uploadedAt,
    this.uploadedBy,
  });

  final String id;

  /// Nome original escolhido pelo usuário — no Storage o arquivo é salvo
  /// com UUID, para evitar colisão e caracteres inválidos.
  final String fileName;
  final String url;
  final String storagePath;
  final String contentType;
  final int sizeBytes;
  final DateTime uploadedAt;
  final String? uploadedBy;

  bool get isImage => contentType.startsWith('image/');
  bool get isPdf => contentType == 'application/pdf';
  bool get isVideo => contentType.startsWith('video/');

  factory Attachment.fromMap(Map<String, dynamic> map) => Attachment(
        id: map['id'] as String? ?? '',
        fileName: map['fileName'] as String? ?? 'arquivo',
        url: map['url'] as String? ?? '',
        storagePath: map['storagePath'] as String? ?? '',
        contentType: map['contentType'] as String? ?? 'application/octet-stream',
        sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
        uploadedAt: (map['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        uploadedBy: map['uploadedBy'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'fileName': fileName,
        'url': url,
        'storagePath': storagePath,
        'contentType': contentType,
        'sizeBytes': sizeBytes,
        'uploadedAt': Timestamp.fromDate(uploadedAt),
        'uploadedBy': uploadedBy,
      };
}
