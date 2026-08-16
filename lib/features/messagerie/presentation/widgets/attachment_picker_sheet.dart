import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_theme.dart';

/// Résultat renvoyé par le bottom sheet de sélection de pièce jointe.
class PieceJointeSelectionnee {
  final File fichier;
  final bool estImage;

  const PieceJointeSelectionnee({
    required this.fichier,
    required this.estImage,
  });
}

// Affiche le choix Caméra / Galerie / Document au clic sur le trombone.
// Retourne le fichier choisi, ou null si l'utilisateur annule.
Future<PieceJointeSelectionnee?> afficherSelecteurPieceJointe(
  BuildContext context,
) {
  return showModalBottomSheet<PieceJointeSelectionnee?>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AttachmentSheetContent(),
  );
}

class _AttachmentSheetContent extends StatelessWidget {
  const _AttachmentSheetContent();

  Future<void> _prendrePhoto(BuildContext context) async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (context.mounted && xfile != null) {
      Navigator.of(
        context,
      ).pop(PieceJointeSelectionnee(fichier: File(xfile.path), estImage: true));
    }
  }

  Future<void> _choisirDansGalerie(BuildContext context) async {
    final xfile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (context.mounted && xfile != null) {
      Navigator.of(
        context,
      ).pop(PieceJointeSelectionnee(fichier: File(xfile.path), estImage: true));
    }
  }

  Future<void> _choisirDocument(BuildContext context) async {
    final resultat = await FilePicker.platform.pickFiles(type: FileType.any);
    final chemin = resultat?.files.single.path;
    if (context.mounted && chemin != null) {
      Navigator.of(
        context,
      ).pop(PieceJointeSelectionnee(fichier: File(chemin), estImage: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Appareil photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _prendrePhoto(context),
            ),
            ListTile(
              leading: const Icon(Icons.photo_outlined, color: Colors.white),
              title: const Text(
                'Galerie',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _choisirDansGalerie(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.insert_drive_file_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Document',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _choisirDocument(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
