enum HealthEventCategory {
  vaccine('Vacina'),
  medication('Medicamento'),
  consultation('Consulta / Retorno'),
  exam('Exame');

  const HealthEventCategory(this.label);
  final String label;
}

class HealthEvent {
  const HealthEvent({
    required this.petId,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.date,
    this.notes = '',
  });

  final int petId;
  final HealthEventCategory category;
  final String title;
  final String subtitle;
  final DateTime date;
  final String notes;
}

