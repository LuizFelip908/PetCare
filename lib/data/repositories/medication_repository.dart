import '../../core/database/database_helper.dart';
import '../models/medication.dart';
import '../models/medication_log.dart';

class MedicationRepository {
  MedicationRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<List<Medication>> getAll({int? petId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'medications',
      where: petId != null ? 'pet_id = ?' : null,
      whereArgs: petId != null ? [petId] : null,
      orderBy: 'is_active DESC, start_date DESC',
    );
    return rows.map(Medication.fromMap).toList();
  }

  Future<Medication?> getById(int id) async {
    final db = await _dbHelper.database;
    final rows =
        await db.query('medications', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Medication.fromMap(rows.first);
  }

  Future<int> insert(Medication medication) async {
    final db = await _dbHelper.database;
    return db.insert('medications', medication.toMap());
  }

  Future<int> update(Medication medication) async {
    if (medication.id == null) {
      throw ArgumentError('Medication id is required for update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      'medications',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('medications', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<MedicationLog>> getLogs({int? medicationId, int? petId}) async {
    final db = await _dbHelper.database;
    String? where;
    List<Object?>? whereArgs;
    if (medicationId != null) {
      where = 'medication_id = ?';
      whereArgs = [medicationId];
    } else if (petId != null) {
      where = 'pet_id = ?';
      whereArgs = [petId];
    }
    final rows = await db.query(
      'medication_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'administered_at DESC',
    );
    return rows.map(MedicationLog.fromMap).toList();
  }

  Future<int> insertLog(MedicationLog log) async {
    final db = await _dbHelper.database;
    return db.insert('medication_logs', log.toMap());
  }

  Future<int> deleteLog(int logId) async {
    final db = await _dbHelper.database;
    return db.delete('medication_logs', where: 'id = ?', whereArgs: [logId]);
  }
}

