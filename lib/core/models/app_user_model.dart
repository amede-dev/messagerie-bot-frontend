class AppUserModel {
  final String id;
  final String nom;
  final String prenom;
  final String? email;
  final String? photoUrl;
  final bool enLigne;

  const AppUserModel({
    required this.id,
    required this.nom,
    required this.prenom,
    this.email,
    this.photoUrl,
    this.enLigne = false,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'].toString(),
      nom: (json['nom'] as String? ?? '').trim(),
      prenom: (json['prenom'] as String? ?? '').trim(),
      email: json['email'] as String?,
      photoUrl: json['photoUrl'] as String?,
      enLigne: json['enLigne'] == true,
    );
  }

  /// Nom affiché, propre quelle que soit la casse d'origine dans la base :
  /// "AMBOARAMPITIAVANA" / " Nomena Sarobidy " -> "Amboarampitiavana Nomena Sarobidy"
  String get nomComplet =>
      '${_capitaliserMots(nom)} ${_capitaliserMots(prenom)}'.trim();

  /// Initiales utilisées pour l'avatar rond (ex : "NA").
  String get initiales {
    final p = prenom.trim();
    final n = nom.trim();
    final i1 = n.isNotEmpty ? n[0].toUpperCase() : '';
    final i2 = p.isNotEmpty ? p[0].toUpperCase() : '';
    final resultat = '$i1$i2';
    return resultat.isEmpty ? '?' : resultat;
  }

  static String _capitaliserMots(String texte) {
    final propre = texte.trim();
    if (propre.isEmpty) return propre;
    return propre
        .split(RegExp(r'\s+'))
        .map(
          (mot) => mot.isEmpty
              ? mot
              : '${mot[0].toUpperCase()}${mot.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}
