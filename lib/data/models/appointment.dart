enum AppointmentType {
  consultation('consultation', 'Consulta Veterinária'),
  followUp('follow_up', 'Retorno'),
  exam('exam', 'Exame'),
  vaccination('vaccination', 'Vacinação'),
  grooming('grooming', 'Banho e Tosa');

  const AppointmentType(this.value, this.label);
  final String value;
  final String label;

  static AppointmentType fromValue(String value) {
    return AppointmentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppointmentType.consultation,
    );
  }
}

class Appointment {
  const Appointment({
    this.id,
    required this.petId,
    required this.type,
    required this.title,
    required this.dateTime,
    this.location = '',
    this.notes = '',
    this.reminderEnabled = true,
    this.completed = false,
    required this.createdAt,
  });

  final int? id;
  final int petId;
  final AppointmentType type;
  final String title;
  final DateTime dateTime;
  final String location;
  final String notes;
  final bool reminderEnabled;
  final bool completed;
  final DateTime createdAt;

  Appointment copyWith({
    int? id,
    int? petId,
    AppointmentType? type,
    String? title,
    DateTime? dateTime,
    String? location,
    String? notes,
    bool? reminderEnabled,
    bool? completed,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      type: type ?? this.type,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'type': type.value,
      'title': title.trim(),
      'date_time': dateTime.toIso8601String(),
      'location': location.trim(),
      'notes': notes.trim(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'completed': completed ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'] as int?,
      petId: map['pet_id'] as int,
      type: AppointmentType.fromValue(map['type'] as String? ?? 'consultation'),
      title: map['title'] as String? ?? '',
      dateTime: DateTime.parse(map['date_time'] as String),
      location: map['location'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      reminderEnabled: (map['reminder_enabled'] as int? ?? 1) == 1,
      completed: (map['completed'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

