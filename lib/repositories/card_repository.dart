import 'package:sqflite/sqflite.dart';
import '../database/database_healper.dart';
import '../models/card.dart';

class CardRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // CREATE
  Future<int> insertCard(PlayingCard card) async {
    try {
      final db = await _dbHelper.database;
      final map = card.toMap()..remove('id');
      return await db.insert(
        'cards',
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('Failed to insert card: $e');
    }
  }

  // READ ALL
  Future<List<PlayingCard>> getAllCards() async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query('cards', orderBy: 'suit ASC, card_name ASC');
      return maps.map((m) => PlayingCard.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to load all cards: $e');
    }
  }

  // READ BY FOLDER
  Future<List<PlayingCard>> getCardsByFolderId(int folderId) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'cards',
        where: 'folder_id = ?',
        whereArgs: [folderId],
        orderBy: 'CASE card_name '
            "WHEN 'Ace' THEN 1 WHEN '2' THEN 2 WHEN '3' THEN 3 "
            "WHEN '4' THEN 4 WHEN '5' THEN 5 WHEN '6' THEN 6 "
            "WHEN '7' THEN 7 WHEN '8' THEN 8 WHEN '9' THEN 9 "
            "WHEN '10' THEN 10 WHEN 'Jack' THEN 11 "
            "WHEN 'Queen' THEN 12 WHEN 'King' THEN 13 "
            'ELSE 99 END ASC',
      );
      return maps.map((m) => PlayingCard.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to load cards for folder $folderId: $e');
    }
  }

  // READ ONE
  Future<PlayingCard?> getCardById(int id) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'cards',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (maps.isEmpty) return null;
      return PlayingCard.fromMap(maps.first);
    } catch (e) {
      throw Exception('Failed to get card by id: $e');
    }
  }

  // UPDATE
  Future<int> updateCard(PlayingCard card) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'cards',
        card.toMap(),
        where: 'id = ?',
        whereArgs: [card.id],
      );
    } catch (e) {
      throw Exception('Failed to update card: $e');
    }
  }

  // DELETE
  Future<int> deleteCard(int id) async {
    try {
      final db = await _dbHelper.database;
      return await db.delete(
        'cards',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to delete card: $e');
    }
  }

  // COUNT BY FOLDER
  Future<int> getCardCountByFolder(int folderId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM cards WHERE folder_id = ?',
      [folderId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // MOVE CARD TO DIFFERENT FOLDER
  Future<int> moveCardToFolder(int cardId, int newFolderId) async {
    try {
      final db = await _dbHelper.database;
      return await db.update(
        'cards',
        {'folder_id': newFolderId},
        where: 'id = ?',
        whereArgs: [cardId],
      );
    } catch (e) {
      throw Exception('Failed to move card: $e');
    }
  }

  // SEARCH BY NAME ACROSS ALL FOLDERS
  Future<List<PlayingCard>> searchCards(String query) async {
    try {
      final db = await _dbHelper.database;
      final maps = await db.query(
        'cards',
        where: 'card_name LIKE ? OR suit LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'suit ASC, card_name ASC',
      );
      return maps.map((m) => PlayingCard.fromMap(m)).toList();
    } catch (e) {
      throw Exception('Failed to search cards: $e');
    }
  }
}
