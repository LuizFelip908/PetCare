import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dateFormat = DateFormat('dd/MM/yyyy', 'pt_BR');
  static final DateFormat _dateTimeFormat =
      DateFormat('dd/MM/yyyy • HH:mm', 'pt_BR');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM', 'pt_BR');
  static final DateFormat _timeFormat = DateFormat('HH:mm', 'pt_BR');
  static final DateFormat _monthYearFormat =
      DateFormat('MMMM yyyy', 'pt_BR');

  static String formatDate(DateTime date) => _dateFormat.format(date);

  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);

  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  static String formatTime(DateTime date) => _timeFormat.format(date);

  static String formatMonthYear(DateTime date) {
    final formatted = _monthYearFormat.format(date);
    if (formatted.isEmpty) return formatted;
    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  static String formatAge(DateTime? birthDate) {
    if (birthDate == null) return 'Idade não informada';
    final now = DateTime.now();
    if (birthDate.isAfter(now)) return 'Data inválida';

    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    if (now.day < birthDate.day) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    if (years == 0 && months == 0) {
      final days = now.difference(birthDate).inDays;
      return days <= 1 ? '1 dia' : '$days dias';
    }
    if (years == 0) {
      return months == 1 ? '1 mês' : '$months meses';
    }
    if (months == 0) {
      return years == 1 ? '1 ano' : '$years anos';
    }
    final yearLabel = years == 1 ? '1 ano' : '$years anos';
    final monthLabel = months == 1 ? '1 mês' : '$months meses';
    return '$yearLabel e $monthLabel';
  }
}

