import 'dart:io';

import 'package:dio/dio.dart';

import 'api_client.dart';

class UploadedFile {
  final String url;
  final String nom;
  final String type;

  const UploadedFile({
    required this.url,
    required this.nom,
    required this.type,
  });
}

class FileUploadService {
  FileUploadService._();

  static final FileUploadService instance = FileUploadService._();

  final ApiClient _api = ApiClient.instance;

  Future<UploadedFile> upload(File fichier) async {
    return _envoyer(fichier, '/api/files/upload');
  }

  Future<UploadedFile> uploadPhotoProfil(File fichier) async {
    return _envoyer(fichier, '/api/files/profile');
  }

  Future<UploadedFile> _envoyer(File fichier, String endpoint) async {
    final nom = fichier.path.split(Platform.pathSeparator).last;
    final extension = nom.split('.').last.toLowerCase();

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        fichier.path,
        filename: nom,
        contentType: _typeMime(extension),
      ),
    });

    final response = await _api.dio.post(endpoint, data: formData);

    final data = response.data as Map<String, dynamic>;

    return UploadedFile(
      url: data['url'].toString(),
      nom: data['nom'].toString(),
      type: data['type'].toString(),
    );
  }

  DioMediaType? _typeMime(String extension) {
    const types = {
      'pdf': ['application', 'pdf'],
      'doc': ['application', 'msword'],
      'docx': [
        'application',
        'vnd.openxmlformats-officedocument.wordprocessingml.document',
      ],
      'xls': ['application', 'vnd.ms-excel'],
      'xlsx': [
        'application',
        'vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      ],
      'jpg': ['image', 'jpeg'],
      'jpeg': ['image', 'jpeg'],
      'png': ['image', 'png'],
      'webp': ['image', 'webp'],
      'gif': ['image', 'gif'],
      'm4a': ['audio', 'mp4'],
      'mp3': ['audio', 'mpeg'],
      'wav': ['audio', 'wav'],
      'aac': ['audio', 'aac'],
      'ogg': ['audio', 'ogg'],
      'mp4': ['video', 'mp4'],
      'mov': ['video', 'quicktime'],
      'webm': ['video', 'webm'],
    };

    final type = types[extension];
    return type == null ? null : DioMediaType(type[0], type[1]);
  }
}
