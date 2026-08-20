class UserProfileModel {
  final String nom;
  final String prenom;
  final String? email;
  final String? parcours;
  final String? niveau;
  final String? photoUrl;
  final int amis;
  final int groupes;

  const UserProfileModel({
    required this.nom,
    required this.prenom,
    this.email,
    this.parcours,
    this.niveau,
    this.photoUrl,
    required this.amis,
    required this.groupes,
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
      groupes: (json['groupes'] as num? ?? 0).toInt(),
    );
  }

  String get nomComplet => '$prenom $nom'.trim();

  String? get formation {
    final valeurs = [parcours, niveau]
        .whereType<String>()
        .map((valeur) => valeur.trim())
        .where((valeur) => valeur.isNotEmpty)
        .toList();
    return valeurs.isEmpty ? null : valeurs.join(' - ');
  }
}
