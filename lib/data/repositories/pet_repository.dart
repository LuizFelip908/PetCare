import '../../core/database/database_helper.dart';
import '../models/pet.dart';

class PetRepository {
  PetRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<List<Pet>> getAll() async {
    final db = await _dbHelper.database;
    final rows = await db.query('pets', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(Pet.fromMap).toList();
  }

  Future<Pet?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.query('pets', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Pet.fromMap(rows.first);
  }

  Future<int> insert(Pet pet) async {
    final db = await _dbHelper.database;
    return db.insert('pets', pet.toMap());
  }

  Future<int> update(Pet pet) async {
    if (pet.id == null) {
      throw ArgumentError('Pet id is required for update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      'pets',
      pet.toMap(),
      where: 'id = ?',
      whereArgs: [pet.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteDemoPets() async {
    final db = await _dbHelper.database;
    return db.delete('pets', where: 'is_demo = 1');
  }

  Future<bool> hasDemoPets() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM pets WHERE is_demo = 1',
    );
    final total = (result.first['total'] as int?) ?? 0;
    return total > 0;
  }

  /// Counts related records so the UI can warn the user before deleting a pet.
  Future<int> countRelatedRecords(int petId) async {
    final db = await _dbHelper.database;
    final tables = [
      'vaccines',
      'medications',
      'appointments',
      'weight_records',
    ];
    int total = 0;
    for (final table in tables) {
      final res = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM $table WHERE pet_id = ?',
        [petId],
      );
      total += (res.first['cnt'] as int?) ?? 0;
    }
    return total;
  }
}

