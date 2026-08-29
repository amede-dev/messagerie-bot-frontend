class UserProfileModel {
  final String nom;
  final String prenom;
  final String? email;
  final String? parcours;
  final String? niveau;
  final String? photoUrl;
  final int amis;

  const UserProfileModel({
    required this.nom,
    required this.prenom,
    this.email,
    this.parcours,
    this.niveau,
    this.photoUrl,
    required this.amis,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      nom: (json['nom'] as String? ?? '').trim(),
      prenom: (json['prenom'] as String? ?? '').trim(),
      email: json['email'] as String?,
      parcours: json['parcours'] as String?,
      niveau: json['niveau'] as String?,
      photoUrl: json['photoUrl'] as String?,
      amis: (json['amis'] as num? ?? 0).toInt(),
    );
  }

  /// Format d'affichage officiel de l'université : NOM Prénom.
  /// Exemple : RAKOTONANDRASANA Amedé.
  String get nomComplet => '$nom $prenom'.trim();

  String? get formation {
    final valeurs = [parcours, niveau]
        .whereType<String>()
        .map((valeur) => valeur.trim())
        .where((valeur) => valeur.isNotEmpty)
        .toList();
    return valeurs.isEmpty ? null : valeurs.join(' - ');
  }
}
