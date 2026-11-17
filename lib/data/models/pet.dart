enum PetSpecies {
  dog('dog', 'Cão'),
  cat('cat', 'Gato');

  const PetSpecies(this.value, this.label);
  final String value;
  final String label;

  static PetSpecies fromValue(String value) {
    return PetSpecies.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PetSpecies.dog,
    );
  }
}

enum PetSex {
  male('male', 'Macho'),
  female('female', 'Fêmea');

  const PetSex(this.value, this.label);
  final String value;
  final String label;

  static PetSex fromValue(String value) {
    return PetSex.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PetSex.male,
    );
  }
}

class Pet {
  const Pet({
    this.id,
    required this.name,
    required this.species,
    this.breed = '',
    required this.sex,
    this.birthDate,
    this.currentWeight,
    this.photoPath,
    this.notes = '',
    this.isDemo = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final PetSpecies species;
  final String breed;
  final PetSex sex;
  final DateTime? birthDate;
  final double? currentWeight;
  final String? photoPath;
  final String notes;
  final bool isDemo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pet copyWith({
    int? id,
    String? name,
    PetSpecies? species,
    String? breed,
    PetSex? sex,
    DateTime? birthDate,
    bool clearBirthDate = false,
    double? currentWeight,
    bool clearWeight = false,
    String? photoPath,
    bool clearPhoto = false,
    String? notes,
    bool? isDemo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Pet(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      sex: sex ?? this.sex,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      currentWeight: clearWeight ? null : (currentWeight ?? this.currentWeight),
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      notes: notes ?? this.notes,
      isDemo: isDemo ?? this.isDemo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name.trim(),
      'species': species.value,
      'breed': breed.trim(),
      'sex': sex.value,
      'birth_date': birthDate?.toIso8601String(),
      'current_weight': currentWeight,
      'photo_path': photoPath,
      'notes': notes.trim(),
      'is_demo': isDemo ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      species: PetSpecies.fromValue(map['species'] as String? ?? 'dog'),
      breed: map['breed'] as String? ?? '',
      sex: PetSex.fromValue(map['sex'] as String? ?? 'male'),
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'] as String)
          : null,
      currentWeight: (map['current_weight'] as num?)?.toDouble(),
      photoPath: map['photo_path'] as String?,
      notes: map['notes'] as String? ?? '',
      isDemo: (map['is_demo'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

