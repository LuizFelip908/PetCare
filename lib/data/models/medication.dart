class Medication {
  const Medication({
    this.id,
    required this.petId,
    required this.name,
    this.dosage = '',
    required this.schedules,
    required this.startDate,
    this.endDate,
    this.instructions = '',
    this.reminderEnabled = true,
    this.isActive = true,
    required this.createdAt,
  });

  final int? id;
  final int petId;
  final String name;
  final String dosage;
  final List<String> schedules; // e.g. ["08:00", "20:00"]
  final DateTime startDate;
  final DateTime? endDate;
  final String instructions;
  final bool reminderEnabled;
  final bool isActive;
  final DateTime createdAt;

  bool get isCurrentlyActive {
    if (!isActive) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (today.isBefore(start)) return true; // Scheduled to start
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (today.isAfter(end)) return false;
    }
    return true;
  }

  Medication copyWith({
    int? id,
    int? petId,
    String? name,
    String? dosage,
    List<String>? schedules,
    DateTime? startDate,
    DateTime? endDate,
    bool clearEndDate = false,
    String? instructions,
    bool? reminderEnabled,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      schedules: schedules ?? this.schedules,
      startDate: startDate ?? this.startDate,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      instructions: instructions ?? this.instructions,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'name': name.trim(),
      'dosage': dosage.trim(),
      'schedules': schedules.join(','),
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'instructions': instructions.trim(),
      'reminder_enabled': reminderEnabled ? 1 : 0,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    final rawSchedules = map['schedules'] as String? ?? '';
    final parsedSchedules = rawSchedules
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Medication(
      id: map['id'] as int?,
      petId: map['pet_id'] as int,
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      schedules: parsedSchedules,
      startDate: DateTime.parse(map['start_date'] as String),
      endDate: map['end_date'] != null
          ? DateTime.tryParse(map['end_date'] as String)
          : null,
      instructions: map['instructions'] as String? ?? '',
      reminderEnabled: (map['reminder_enabled'] as int? ?? 1) == 1,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

