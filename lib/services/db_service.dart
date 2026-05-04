import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/tarea.dart';

class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  Database? _db;

  /// Se incrementa cada vez que se escribe en la BD (insertar / completar).
  /// Los widgets que necesiten reaccionar a cambios pueden suscribirse aquí
  /// sin necesidad de polling ni Riverpod.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Lanza [UnsupportedError] si se llama en Web — sqflite no soporta el
  /// navegador. Todos los métodos públicos tienen un guard `kIsWeb` propio
  /// que devuelve un valor seguro antes de llegar aquí, de modo que la app
  /// nunca se congela: esta excepción solo se dispara si alguien usa `db`
  /// directamente en un contexto no previsto.
  Future<Database> get db async {
    if (kIsWeb) {
      throw UnsupportedError(
        'DbService: sqflite no está soportado en Web. '
        'Las tareas no se persistirán en el navegador.',
      );
    }
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

  // ── Escritura ─────────────────────────────────────────────────────────────

  Future<void> insertarTarea(Tarea tarea) async {
    if (kIsWeb) return; // no-op en web
    final database = await db;
    await database.insert(
      'tareas',
      tarea.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    revision.value++;
  }

  Future<void> completarTarea(String id) async {
    if (kIsWeb) return; // no-op en web
    final database = await db;
    await database.update(
      'tareas',
      {'completada': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    revision.value++;
  }

  // ── Lectura ───────────────────────────────────────────────────────────────

  Future<List<Tarea>> obtenerTareas(String uid) async {
    if (kIsWeb) return [];
    final database = await db;
    final maps = await database.query(
      'tareas',
      where: 'uid = ? AND completada = 0',
      whereArgs: [uid],
    );
    return maps.map((m) => Tarea.fromMap(m)).toList();
  }

  Future<List<Tarea>> obtenerTareasPorFecha(String uid, DateTime fecha) async {
    if (kIsWeb) return [];
    final database = await db;
    final maps = await database.query(
      'tareas',
      where: 'uid = ? AND completada = 0',
      whereArgs: [uid],
    );
    final tareas = maps.map((m) => Tarea.fromMap(m)).toList();
    return tareas.where((t) {
      if (t.startDate == null || t.endDate == null) {
        return t.fechaEntrega.year == fecha.year &&
            t.fechaEntrega.month == fecha.month &&
            t.fechaEntrega.day == fecha.day;
      }
      final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);
      final start = DateTime(
          t.startDate!.year, t.startDate!.month, t.startDate!.day);
      final end =
          DateTime(t.endDate!.year, t.endDate!.month, t.endDate!.day);
      return !fechaSinHora.isBefore(start) && !fechaSinHora.isAfter(end);
    }).toList();
  }

  // ── Contadores ────────────────────────────────────────────────────────────

  Future<int> contarCompletadas(String uid) async {
    if (kIsWeb) return 0;
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as total FROM tareas WHERE uid = ? AND completada = 1',
      [uid],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> contarPendientes(String uid) async {
    if (kIsWeb) return 0;
    final database = await db;
    final result = await database.rawQuery(
      'SELECT COUNT(*) as total FROM tareas WHERE uid = ? AND completada = 0',
      [uid],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> contarVencidas(String uid) async {
    if (kIsWeb) return 0;
    final database = await db;
    final hoy = DateTime.now().toIso8601String();
    final result = await database.rawQuery(
      'SELECT COUNT(*) as total FROM tareas WHERE uid = ? AND completada = 0 AND fechaEntrega < ?',
      [uid, hoy],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> calcularRacha(String uid) async {
    if (kIsWeb) return 0;
    final database = await db;
    final maps = await database.query(
      'tareas',
      where: 'uid = ? AND completada = 1',
      whereArgs: [uid],
      orderBy: 'fechaEntrega DESC',
    );

    if (maps.isEmpty) return 0;

    final fechas = maps
        .map((m) => DateTime.parse(m['fechaEntrega'] as String))
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int racha = 1;
    for (int i = 0; i < fechas.length - 1; i++) {
      final diff = fechas[i].difference(fechas[i + 1]).inDays;
      if (diff == 1) {
        racha++;
      } else {
        break;
      }
    }
    return racha;
  }
}
