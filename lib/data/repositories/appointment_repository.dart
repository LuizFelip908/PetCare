import '../../core/database/database_helper.dart';
import '../models/appointment.dart';

class AppointmentRepository {
  AppointmentRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;

  Future<List<Appointment>> getAll({int? petId}) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'appointments',
      where: petId != null ? 'pet_id = ?' : null,
      whereArgs: petId != null ? [petId] : null,
      orderBy: 'date_time ASC',
    );
    return rows.map(Appointment.fromMap).toList();
  }

  Future<List<Appointment>> getUpcoming({int limit = 10}) async {
    final db = await _dbHelper.database;
    final nowIso =
        DateTime.now().subtract(const Duration(hours: 1)).toIso8601String();
    final rows = await db.query(
      'appointments',
      where: 'completed = 0 AND date_time >= ?',
      whereArgs: [nowIso],
      orderBy: 'date_time ASC',
      limit: limit,
    );
    return rows.map(Appointment.fromMap).toList();
  }

  Future<int> insert(Appointment appointment) async {
    final db = await _dbHelper.database;
    return db.insert('appointments', appointment.toMap());
  }

  Future<int> update(Appointment appointment) async {
    if (appointment.id == null) {
      throw ArgumentError('Appointment id is required for update.');
    }
    final db = await _dbHelper.database;
    return db.update(
      'appointments',
      appointment.toMap(),
      where: 'id = ?',
      whereArgs: [appointment.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await _dbHelper.database;
    return db.delete('appointments', where: 'id = ?', whereArgs: [id]);
  }
}

