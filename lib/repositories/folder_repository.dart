import 'package:sqflite/sqflite.dart';
import '../database/database_healper.dart';
import '../models/folder.dart';

class FolderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // CREATE
  Future<int> insertFolder(Folder folder) async {
    try {
      final db = await _dbHelper.database;
      return await db.insert(
        'folders',
        folder.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert folder: $e');
    }
  }

  // READ ALL
  Future<List<Folder>> getAllFolders() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('folders', orderBy: 'id ASC');
      return maps.map((m) => Folder.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to load folders: $e');
    }
  }

  // READ ONE
  Future<Folder?> getFolderById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'folders',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return Folder.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to get folder by id: $e');
    }
  }

  // UPDATE
  Future<int> updateFolder(Folder folder) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'folders',
        folder.toMap(),
        where: 'id = ?',
        whereArgs: [folder.id],
      );
    } catch (e) {
      throw Exception('Failed to update folder: $e');
    }
  }

  // DELETE (cascades to cards via FK)
  Future<int> deleteFolder(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'folders',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete folder: $e');
    }
  }

  // COUNT
  Future<int> getFolderCount() async {
    final db = await _dbHelper.database;
    final result =
        await db.rawQuery('SELECT COUNT(*) AS count FROM folders');
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
