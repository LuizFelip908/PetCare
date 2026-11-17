import '../../core/database/database_helper.dart';
import '../models/weight_record.dart';

class WeightRepository {
  WeightRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<List<WeightRecord>> getByPet(int petId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'weight_records',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'recorded_at ASC',
    );
    return rows.map(WeightRecord.fromMap).toList();
  }

  Future<int> insert(WeightRecord record) async {
    final db = await _dbHelper.database;
    final id = await db.insert('weight_records', record.toMap());
    await _syncPetCurrentWeight(record.petId);
    return id;
  }

  Future<int> update(WeightRecord record) async {
    if (record.id == null) {
      throw ArgumentError('WeightRecord id is required for update.');
    }
    final db = await _dbHelper.database;
    final count = await db.update(
      'weight_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
    await _syncPetCurrentWeight(record.petId);
    return count;
  }

  Future<int> delete(int id, int petId) async {
    final db = await _dbHelper.database;
    final count = await db.delete(
      'weight_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _syncPetCurrentWeight(petId);
    return count;
  }

  Future<void> _syncPetCurrentWeight(int petId) async {
    final db = await _dbHelper.database;
    final latest = await db.query(
      'weight_records',
      where: 'pet_id = ?',
      whereArgs: [petId],
      orderBy: 'recorded_at DESC, id DESC',
      limit: 1,
    );
    if (latest.isNotEmpty) {
      final latestWeight = (latest.first['weight_kg'] as num).toDouble();
      await db.update(
        'pets',
        {
          'current_weight': latestWeight,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [petId],
      );
    }
  }
}

