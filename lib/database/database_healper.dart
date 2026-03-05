import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('card_organizer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onOpen: (db) async {
        // Enable foreign keys every time the database is opened
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');

    // Create Folders table
    await db.execute('''
      CREATE TABLE folders (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp   TEXT NOT NULL
      )
    ''');

    // Create Cards table with ON DELETE CASCADE foreign key
    await db.execute('''
      CREATE TABLE cards (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        card_name  TEXT NOT NULL,
        suit       TEXT NOT NULL,
        image_url  TEXT,
        folder_id  INTEGER NOT NULL,
        FOREIGN KEY (folder_id) REFERENCES folders (id)
          ON DELETE CASCADE
      )
    ''');

    await _prepopulateFolders(db);
    await _prepopulateCards(db);
  }

  Future<void> _prepopulateFolders(Database db) async {
    final folders = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    for (final name in folders) {
      await db.insert('folders', {
        'folder_name': name,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> _prepopulateCards(Database db) async {
    // Folder IDs are 1-4 in insertion order: Hearts, Diamonds, Clubs, Spades
    final suits = ['Hearts', 'Diamonds', 'Clubs', 'Spades'];
    const cardNames = [
      'Ace', '2', '3', '4', '5', '6', '7',
      '8', '9', '10', 'Jack', 'Queen', 'King'
    ];

    // Map suit → abbreviated code used by Deck of Cards API
    const suitCode = {
      'Hearts': 'H',
      'Diamonds': 'D',
      'Clubs': 'C',
      'Spades': 'S',
    };
    const rankCode = {
      'Ace': 'A',
      '2': '2', '3': '3', '4': '4', '5': '5',
      '6': '6', '7': '7', '8': '8', '9': '9', '10': '0',
      'Jack': 'J', 'Queen': 'Q', 'King': 'K',
    };

    for (int i = 0; i < suits.length; i++) {
      final suit = suits[i];
      final folderId = i + 1; // IDs start at 1
      for (final cardName in cardNames) {
        final code = '${rankCode[cardName]}${suitCode[suit]}';
        final imageUrl =
            'https://deckofcardsapi.com/static/img/$code.png';
        await db.insert('cards', {
          'card_name': cardName,
          'suit': suit,
          'image_url': imageUrl,
          'folder_id': folderId,
        });
      }
    }
  }

  // ── Debug helper ─────────────────────────────────────────────────────────
  Future<void> printDatabaseContents() async {
    final db = await database;

    print('=== FOLDERS ===');
    final folders = await db.query('folders');
    for (final f in folders) {
      print(f);
    }

    print('\n=== CARDS (first 10) ===');
    final cards = await db.query('cards', limit: 10);
    for (final c in cards) {
      print(c);
    }

    print('\n=== CARD COUNT BY FOLDER ===');
    final counts = await db.rawQuery(
      'SELECT f.folder_name, COUNT(c.id) AS card_count '
      'FROM folders f LEFT JOIN cards c ON f.id = c.folder_id '
      'GROUP BY f.id',
    );
    for (final row in counts) {
      print(row);
    }
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
