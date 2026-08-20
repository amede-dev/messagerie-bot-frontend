class NotificationModel {
  final String id;
  final String type;
  final String contenu;
  final bool lue;
  final DateTime dateCreation;

  const NotificationModel({required this.id, required this.type,
    required this.contenu, required this.lue, required this.dateCreation});

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'].toString(),
    type: json['type'] as String? ?? 'Information',
    contenu: json['contenu'] as String? ?? '',
    lue: json['lu'] as bool? ?? false,
    dateCreation: DateTime.tryParse(json['dateCreation'] as String? ?? '') ?? DateTime.now(),
  );
}
