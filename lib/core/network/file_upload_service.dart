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

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(fichier.path, filename: nom),
    });

    final response = await _api.dio.post(endpoint, data: formData);

    final data = response.data as Map<String, dynamic>;

    return UploadedFile(
      url: data['url'].toString(),
      nom: data['nom'].toString(),
      type: data['type'].toString(),
    );
  }
}
