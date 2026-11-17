class WeightRecord {
  const WeightRecord({
    this.id,
    required this.petId,
    required this.weightKg,
    required this.recordedAt,
    this.notes = '',
  });

  final int? id;
  final int petId;
  final double weightKg;
  final DateTime recordedAt;
  final String notes;

  WeightRecord copyWith({
    int? id,
    int? petId,
    double? weightKg,
    DateTime? recordedAt,
    String? notes,
  }) {
    return WeightRecord(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      weightKg: weightKg ?? this.weightKg,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'weight_kg': weightKg,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes.trim(),
    };
  }

  factory WeightRecord.fromMap(Map<String, dynamic> map) {
    return WeightRecord(
      id: map['id'] as int?,
      petId: map['pet_id'] as int,
      weightKg: (map['weight_kg'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recorded_at'] as String),
      notes: map['notes'] as String? ?? '',
    );
  }
}

