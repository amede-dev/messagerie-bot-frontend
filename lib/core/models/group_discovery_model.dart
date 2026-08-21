class GroupDiscoveryModel {
  final String id;
  final String nom;
  final int nombreMembres;

  const GroupDiscoveryModel({
    required this.id,
    required this.nom,
    required this.nombreMembres,
  });

  factory GroupDiscoveryModel.fromJson(Map<String, dynamic> json) {
    return GroupDiscoveryModel(
      id: json['id'].toString(),
      nom: json['nom'] as String? ?? 'Groupe sans nom',
      nombreMembres: (json['nombreMembres'] as num? ?? 0).toInt(),
    );
  }
}
