import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Résultat d'une sélection de pièce jointe.
class SelectionPieceJointe {
  final File fichier;
  final bool estImage;

  const SelectionPieceJointe({required this.fichier, required this.estImage});
}

// Ouvre la galerie et sélectionne une image.
Future<SelectionPieceJointe?> choisirImageDepuisGalerie() async {
  final picker = ImagePicker();

  final image = await picker.pickImage(
    source: ImageSource.gallery,
    imageQuality: 85,
  );

  if (image == null) {
    return null;
  }

  return SelectionPieceJointe(fichier: File(image.path), estImage: true);
}

// Ouvre le sélecteur de fichiers.
Future<SelectionPieceJointe?> choisirFichier() async {
  final resultat = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.any,
  );

  if (resultat == null || resultat.files.single.path == null) {
    return null;
  }

  final fichier = File(resultat.files.single.path!);

  final extension = resultat.files.single.extension?.toLowerCase();

  final estImage = ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);

  return SelectionPieceJointe(fichier: fichier, estImage: estImage);
}

// Bottom sheet permettant de choisir le type de pièce jointe.
Future<SelectionPieceJointe?> afficherAttachmentPicker(
  BuildContext context,
) async {
  return showModalBottomSheet<SelectionPieceJointe?>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajouter une pièce jointe',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),

              const SizedBox(height: 16),

              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.photo_outlined)),
                title: const Text('Galerie'),
                subtitle: const Text('Envoyer une image'),
                onTap: () async {
                  final selection = await choisirImageDepuisGalerie();

                  if (context.mounted) {
                    Navigator.of(context).pop(selection);
                  }
                },
              ),

              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.insert_drive_file_outlined),
                ),
                title: const Text('Document'),
                subtitle: const Text('PDF, Word, fichier, etc.'),
                onTap: () async {
                  final selection = await choisirFichier();

                  if (context.mounted) {
                    Navigator.of(context).pop(selection);
                  }
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}
