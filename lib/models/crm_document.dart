class CrmDocument {
  const CrmDocument({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.projectId,
    required this.projectName,
    required this.type,
    required this.title,
    required this.description,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.status,
    required this.downloadEndpoint,
    required this.createdAt,
  });

  factory CrmDocument.fromJson(Map<String, dynamic> json) {
    return CrmDocument(
      id: (json['id'] as num?)?.toInt() ?? 0,
      clientId: (json['client_id'] as num?)?.toInt() ?? 0,
      clientName: json['client_name'] as String? ?? '',
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      projectName: json['project_name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      mimeType: json['mime_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      downloadEndpoint: json['download_url'] as String? ?? '',
      createdAt: json['created_at'] as String?,
    );
  }

  final int id;
  final int clientId;
  final String clientName;
  final int projectId;
  final String projectName;
  final String type;
  final String title;
  final String description;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final String status;
  final String downloadEndpoint;
  final String? createdAt;
}

class DocumentDownload {
  const DocumentDownload({
    required this.fileName,
    required this.mimeType,
    required this.fileSize,
    required this.downloadUrl,
  });

  factory DocumentDownload.fromJson(Map<String, dynamic> json) {
    return DocumentDownload(
      fileName: json['file_name'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      downloadUrl: json['download_url'] as String? ?? '',
    );
  }

  final String fileName;
  final String mimeType;
  final int fileSize;
  final String downloadUrl;
}
