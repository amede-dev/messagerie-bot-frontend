import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Résultat renvoyé par le bottom sheet de sélection de pièce jointe.
class PieceJointeSelectionnee {
  final File fichier;
  final bool estImage;

  const PieceJointeSelectionnee({
    required this.fichier,
    required this.estImage,
  });
}

/// Ouvre directement la galerie native du téléphone. Elle affiche les photos
/// réelles de l'appareil et permet d'utiliser son raccourci appareil photo.
Future<PieceJointeSelectionnee?> choisirImageDepuisGalerie() async {
  final xfile = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    imageQuality: 80,
  );
  if (xfile == null) return null;
  return PieceJointeSelectionnee(fichier: File(xfile.path), estImage: true);
}
