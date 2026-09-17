import 'package:flutter/services.dart';

typedef PdfShareOverride =
    Future<void> Function({
      required String filePath,
      required String fileName,
      required String text,
      required String subject,
    });

class PdfShareService {
  const PdfShareService();

  static const MethodChannel _channel = MethodChannel(
    'com.daphnex.crm/document_picker',
  );

  static PdfShareOverride? debugShareOverride;

  Future<void> sharePdf({
    required String filePath,
    required String fileName,
    required String text,
    required String subject,
    String? targetPackage,
  }) async {
    final override = debugShareOverride;
    if (override != null) {
      await override(
        filePath: filePath,
        fileName: fileName,
        text: text,
        subject: subject,
      );
      return;
    }
    await _channel.invokeMethod<void>('sharePdf', <String, Object?>{
      'filePath': filePath,
      'fileName': fileName,
      'mimeType': 'application/pdf',
      'text': text,
      'subject': subject,
      'targetPackage': targetPackage,
    });
  }
}
