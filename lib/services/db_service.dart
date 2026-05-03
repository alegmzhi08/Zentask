import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tarea.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'zentask.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tareas (
            id TEXT PRIMARY KEY,
            nombre TEXT,
            materia TEXT,
            fechaEntrega TEXT,
            startDate TEXT,
            endDate TEXT,
            diasTrabajo TEXT,
            tiempoSesion INTEGER,
            sesionesPorDia INTEGER,
            completada INTEGER,
            uid TEXT
          )
        ''');
      },
    );
  }

  // Guardar tarea
  Future<void> insertarTarea(Tarea tarea) async {
    final database = await db;
    await database.insert(
      'tareas',
      tarea.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Obtener todas las tareas del usuario actual
  Future<List<Tarea>> obtenerTareas(String uid) async {
    final database = await db;
    final maps = await database.query(
      'tareas',
      where: 'uid = ? AND completada = 0',
      whereArgs: [uid],
    );
    return maps.map((m) => Tarea.fromMap(m)).toList();
  }

  // Obtener tareas para un día específico
  Future<List<Tarea>> obtenerTareasPorFecha(String uid, DateTime fecha) async {
    final database = await db;
    final maps = await database.query(
      'tareas',
      where: 'uid = ? AND completada = 0',
      whereArgs: [uid],
    );
    final tareas = maps.map((m) => Tarea.fromMap(m)).toList();

    // Filtra las tareas cuyo rango incluye la fecha seleccionada
    return tareas.where((t) {
      if (t.startDate == null || t.endDate == null) {
        return t.fechaEntrega.year == fecha.year &&
            t.fechaEntrega.month == fecha.month &&
            t.fechaEntrega.day == fecha.day;
      }
      final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
      final start = DateTime(t.startDate!.year, t.startDate!.month, t.startDate!.day);
      final end = DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day);
      return !fechaSinHora.isBefore(start) && !fechaSinHora.isAfter(end);
    }).toList();
  }

  // Marcar tarea como completada
  Future<void> completarTarea(String id) async {
    final database = await db;
    await database.update(
      'tareas',
      {'completada': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Contar tareas completadas del usuario
  Future<int> contarCompletadas(String uid) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as total FROM tareas WHERE uid = ? AND completada = 1',
      [uid],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Contar tareas pendientes del usuario
  Future<int> contarPendientes(String uid) async {
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as total FROM tareas WHERE uid = ? AND completada = 0',
      [uid],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}