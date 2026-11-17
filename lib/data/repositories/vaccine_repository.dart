import '../../core/database/database_helper.dart';
import '../models/vaccine.dart';

class VaccineRepository {
  VaccineRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<List<Vaccine>> getAll({int? petId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'vaccines',
      where: petId != null ? 'pet_id = ?' : null,
      whereArgs: petId != null ? [petId] : null,
      orderBy: 'applied_at DESC',
    );
    return rows.map(Vaccine.fromMap).toList();
  }

  Future<List<Vaccine>> getUpcomingDoses() async {
    final db = await _dbHelper.database;
    final nowIso = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String();
    final rows = await db.query(
      'vaccines',
      where: 'next_dose_at IS NOT NULL AND next_dose_at >= ?',
      whereArgs: [nowIso],
      orderBy: 'next_dose_at ASC',
    );
    return rows.map(Vaccine.fromMap).toList();
  }

  Future<int> insert(Vaccine vaccine) async {
    final db = await _dbHelper.database;
    return db.insert('vaccines', vaccine.toMap());
  }

  Future<int> update(Vaccine vaccine) async {
    if (vaccine.id == null) {
      throw ArgumentError('Vaccine id is required for update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      'vaccines',
      vaccine.toMap(),
      where: 'id = ?',
      whereArgs: [vaccine.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('vaccines', where: 'id = ?', whereArgs: [id]);
  }
}

