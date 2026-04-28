import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDB {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sahayatri.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE yatra_cards (
            id INTEGER PRIMARY KEY,
            user_id INTEGER,
            pnr TEXT,
            train_number TEXT,
            boarding_station_id INTEGER,
            destination_station_id INTEGER,
            berth_info TEXT,
            journey_date TEXT,
            status TEXT,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE stations (
            id INTEGER PRIMARY KEY,
            code TEXT,
            name TEXT,
            lat REAL,
            lon REAL,
            zone TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE breadcrumbs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            yatra_id INTEGER,
            lat REAL,
            lon REAL,
            snapped_lat REAL,
            snapped_lon REAL,
            timestamp TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE train_status_cache (
            train_number TEXT PRIMARY KEY,
            current_lat REAL,
            current_lon REAL,
            delay_minutes INTEGER,
            last_fetched_at TEXT
          )
        ''');
      },
    );
  }

  // Yatra Cards
  static Future<void> cacheYatraCards(List<Map<String, dynamic>> cards) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('yatra_cards');
    for (final card in cards) {
      batch.insert('yatra_cards', card, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCachedYatraCards() async {
    final db = await database;
    return db.query('yatra_cards', orderBy: 'journey_date DESC');
  }

  // Stations
  static Future<void> cacheStations(List<Map<String, dynamic>> stations) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('stations');
    for (final station in stations) {
      batch.insert('stations', station, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Map<String, dynamic>>> getCachedStations() async {
    final db = await database;
    return db.query('stations', orderBy: 'name');
  }

  // Breadcrumbs
  static Future<void> addBreadcrumb(Map<String, dynamic> breadcrumb) async {
    final db = await database;
    await db.insert('breadcrumbs', breadcrumb);
  }

  static Future<List<Map<String, dynamic>>> getBreadcrumbs(int yatraId) async {
    final db = await database;
    return db.query('breadcrumbs',
        where: 'yatra_id = ?', whereArgs: [yatraId], orderBy: 'timestamp');
  }

  // Train Status
  static Future<void> cacheTrainStatus(Map<String, dynamic> status) async {
    final db = await database;
    await db.insert('train_status_cache', status,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getCachedTrainStatus(
      String trainNumber) async {
    final db = await database;
    final results = await db.query('train_status_cache',
        where: 'train_number = ?', whereArgs: [trainNumber]);
    return results.isNotEmpty ? results.first : null;
  }
}
