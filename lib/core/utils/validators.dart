class AppValidators {
  AppValidators._();

  static String? requiredText(String? value, {String fieldName = 'Este campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName é obrigatório.';
    }
    return null;
  }

  static String? positiveWeight(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'Informe o peso do animal.' : null;
    }
    final normalized = value.trim().replaceAll(',', '.');
    final parsed = double.tryParse(normalized);
    if (parsed == null) {
      return 'Informe um peso numérico válido.';
    }
    if (parsed <= 0) {
      return 'O peso deve ser maior que zero.';
    }
    if (parsed > 200) {
      return 'Peso acima do limite esperado (200 kg).';
    }
    return null;
  }

  static double? parseWeight(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  static String? validateBirthDate(DateTime? birthDate) {
    if (birthDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 23, 59, 59);
    if (birthDate.isAfter(today)) {
      return 'A data de nascimento não pode ser futura.';
    }
    if (birthDate.year < 1985) {
      return 'Informe uma data de nascimento válida.';
    }
    return null;
  }

  static String? validateDateRange(DateTime start, DateTime? end) {
    if (end == null) return null;
    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    if (endDay.isBefore(startDay)) {
      return 'A data de término não pode ser anterior ao início.';
    }
    return null;
  }

  static String? validateNextDoseDate(DateTime appliedAt, DateTime? nextDose) {
    if (nextDose == null) return null;
    final appliedDay = DateTime(appliedAt.year, appliedAt.month, appliedAt.day);
    final nextDay = DateTime(nextDose.year, nextDose.month, nextDose.day);
    if (!nextDay.isAfter(appliedDay)) {
      return 'A próxima dose deve ser posterior à data de aplicação.';
    }
    return null;
  }

  static String? validateMedicationTimes(List<String> times) {
    if (times.isEmpty) {
      return 'Adicione pelo menos um horário de administração.';
    }
    return null;
  }
}

