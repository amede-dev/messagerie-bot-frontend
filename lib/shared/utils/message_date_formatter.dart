import 'package:intl/intl.dart';

/// Format court utilisé pour les dates du dernier message.
class MessageDateFormatter {
  const MessageDateFormatter._();

  static String format(DateTime date, {DateTime? now}) {
    final maintenant = now ?? DateTime.now();
    final aujourdHui = DateTime(
      maintenant.year,
      maintenant.month,
      maintenant.day,
    );
    final jourMessage = DateTime(date.year, date.month, date.day);
    final difference = aujourdHui.difference(jourMessage).inDays;
    final heure = DateFormat('HH:mm').format(date);
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    if (difference == 0) return heure;
    if (difference == 1) return 'Hier $heure';
    if (difference > 1 && difference < 7) {
      return '${jours[date.weekday - 1]} $heure';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  static String formatPresence(DateTime date, {DateTime? now}) {
    final maintenant = now ?? DateTime.now();
    final difference = maintenant.difference(date);

    if (difference.isNegative || difference.inMinutes < 1) {
      return 'Hors ligne depuis moins d’une minute';
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return 'Hors ligne depuis $minutes min';
    }
    if (difference.inHours < 24) {
      final heures = difference.inHours;
      return 'Hors ligne depuis $heures ${heures == 1 ? 'heure' : 'heures'}';
    }

    final jours = difference.inDays;
    return 'Hors ligne depuis $jours ${jours == 1 ? 'jour' : 'jours'}';
  }
}
