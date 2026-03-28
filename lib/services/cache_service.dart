import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'uniplan_cache.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Cache table for timetable data
    await db.execute('''
      CREATE TABLE timetable_cache (
        id TEXT PRIMARY KEY,
        semester_id TEXT,
        division_id TEXT,
        day TEXT,
        data TEXT,
        last_updated INTEGER
      )
    ''');

    // Cache table for semesters
    await db.execute('''
      CREATE TABLE semesters_cache (
        id TEXT PRIMARY KEY,
        name TEXT,
        last_updated INTEGER
      )
    ''');

    // Cache table for divisions
    await db.execute('''
      CREATE TABLE divisions_cache (
        id TEXT PRIMARY KEY,
        name TEXT,
        last_updated INTEGER
      )
    ''');

    // Cache table for subjects
    await db.execute('''
      CREATE TABLE subjects_cache (
        id TEXT PRIMARY KEY,
        name TEXT,
        last_updated INTEGER
      )
    ''');

    // Cache table for teachers
    await db.execute('''
      CREATE TABLE teachers_cache (
        id TEXT PRIMARY KEY,
        name TEXT,
        last_updated INTEGER
      )
    ''');

    // Metadata table
    await db.execute('''
      CREATE TABLE cache_metadata (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
  }

  // Save timetable data
  Future<void> cacheTimetable({
    required String semesterId,
    required String divisionId,
    required String day,
    required Map<String, dynamic> data,
  }) async {
    final db = await database;
    final id = '$semesterId-$divisionId-$day';
    
    await db.insert(
      'timetable_cache',
      {
        'id': id,
        'semester_id': semesterId,
        'division_id': divisionId,
        'day': day,
        'data': jsonEncode(data),
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get cached timetable data
  Future<Map<String, dynamic>?> getCachedTimetable({
    required String semesterId,
    required String divisionId,
    required String day,
  }) async {
    final db = await database;
    final id = '$semesterId-$divisionId-$day';
    
    final result = await db.query(
      'timetable_cache',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (result.isEmpty) return null;

    final data = result.first['data'] as String;
    return jsonDecode(data) as Map<String, dynamic>;
  }

  // Save semesters
  Future<void> cacheSemesters(List<Map<String, dynamic>> semesters) async {
    final db = await database;
    final batch = db.batch();

    for (var semester in semesters) {
      batch.insert(
        'semesters_cache',
        {
          'id': semester['id'],
          'name': semester['name'],
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Get cached semesters
  Future<List<Map<String, dynamic>>> getCachedSemesters() async {
    final db = await database;
    final result = await db.query('semesters_cache', orderBy: 'name');
    return result.map((row) => {
      'id': row['id'],
      'name': row['name'],
    }).toList();
  }

  // Save divisions
  Future<void> cacheDivisions(List<Map<String, dynamic>> divisions) async {
    final db = await database;
    final batch = db.batch();

    for (var division in divisions) {
      batch.insert(
        'divisions_cache',
        {
          'id': division['id'],
          'name': division['name'],
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  // Get cached divisions
  Future<List<Map<String, dynamic>>> getCachedDivisions() async {
    final db = await database;
    final result = await db.query('divisions_cache', orderBy: 'name');
    return result.map((row) => {
      'id': row['id'],
      'name': row['name'],
    }).toList();
  }

  // Save subjects
  Future<void> cacheSubjects(Map<String, String> subjects) async {
    final db = await database;
    final batch = db.batch();

    subjects.forEach((id, name) {
      batch.insert(
        'subjects_cache',
        {
          'id': id,
          'name': name,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    await batch.commit(noResult: true);
  }

  // Get cached subjects
  Future<Map<String, String>> getCachedSubjects() async {
    final db = await database;
    final result = await db.query('subjects_cache');
    return {
      for (var row in result) row['id'] as String: row['name'] as String
    };
  }

  // Save teachers
  Future<void> cacheTeachers(Map<String, String> teachers) async {
    final db = await database;
    final batch = db.batch();

    teachers.forEach((id, name) {
      batch.insert(
        'teachers_cache',
        {
          'id': id,
          'name': name,
          'last_updated': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });

    await batch.commit(noResult: true);
  }

  // Get cached teachers
  Future<Map<String, String>> getCachedTeachers() async {
    final db = await database;
    final result = await db.query('teachers_cache');
    return {
      for (var row in result) row['id'] as String: row['name'] as String
    };
  }

  // Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final db = await database;
    final result = await db.query(
      'cache_metadata',
      where: 'key = ?',
      whereArgs: ['last_sync'],
    );

    if (result.isEmpty) return null;
    final timestamp = int.tryParse(result.first['value'] as String? ?? '');
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  // Set last sync time
  Future<void> setLastSyncTime() async {
    final db = await database;
    await db.insert(
      'cache_metadata',
      {
        'key': 'last_sync',
        'value': DateTime.now().millisecondsSinceEpoch.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Clear all cache
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('timetable_cache');
    await db.delete('semesters_cache');
    await db.delete('divisions_cache');
    await db.delete('subjects_cache');
    await db.delete('teachers_cache');
    await db.delete('cache_metadata');
    debugPrint('Cache cleared');
  }
}
