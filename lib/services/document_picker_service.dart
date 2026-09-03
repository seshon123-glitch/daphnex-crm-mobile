import 'package:flutter/services.dart';

class PickedCrmDocument {
  const PickedCrmDocument({
    required this.filePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
  });

  factory PickedCrmDocument.fromMap(Map<dynamic, dynamic> value) {
    return PickedCrmDocument(
      filePath: value['filePath'] as String? ?? '',
      fileName: value['fileName'] as String? ?? '',
      mimeType: value['mimeType'] as String? ?? '',
      fileSize: (value['fileSize'] as num?)?.toInt() ?? 0,
    );
  }

  final String filePath;
  final String fileName;
  final String mimeType;
  final int fileSize;
}

abstract interface class DocumentPickerService {
  Future<PickedCrmDocument?> pickDocument();
}

class AndroidDocumentPickerService implements DocumentPickerService {
  const AndroidDocumentPickerService();

  static const MethodChannel _channel = MethodChannel(
    'com.daphnex.crm/document_picker',
  );

  @override
  Future<PickedCrmDocument?> pickDocument() async {
    final selected = await _channel.invokeMapMethod<String, Object?>(
      'pickDocument',
    );
    if (selected == null) return null;
    return PickedCrmDocument.fromMap(selected);
  }
}
