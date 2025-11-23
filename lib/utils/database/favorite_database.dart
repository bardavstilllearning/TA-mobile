import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class FavoriteDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'favorites.db');

    return await openDatabase(
      path,
      version: 2, // ✅ Increment version untuk re-create table
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            worker_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            job_title TEXT NOT NULL,
            rating REAL,
            distance REAL,
            price REAL,
            gender TEXT,
            photo TEXT,
            total_orders INTEGER,
            created_at TEXT,
            UNIQUE(worker_id, user_id)
          )
        ''');
        print('✅ Favorites table created');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // ✅ Drop and recreate table on upgrade
        await db.execute('DROP TABLE IF EXISTS favorites');
        await db.execute('''
          CREATE TABLE favorites(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            worker_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            job_title TEXT NOT NULL,
            rating REAL,
            distance REAL,
            price REAL,
            gender TEXT,
            photo TEXT,
            total_orders INTEGER,
            created_at TEXT,
            UNIQUE(worker_id, user_id)
          )
        ''');
        print('✅ Favorites table upgraded');
      },
    );
  }

  // ✅ FIXED: Add favorite with proper error handling
  static Future<bool> addFavorite(
      Map<String, dynamic> worker, int userId) async {
    try {
      final db = await database;

      // Check if already exists
      final existing = await db.query(
        'favorites',
        where: 'worker_id = ? AND user_id = ?',
        whereArgs: [worker['id'], userId],
      );

      if (existing.isNotEmpty) {
        print('⚠️ Worker ${worker['id']} already in favorites');
        return false;
      }

      // Insert new favorite
      final result = await db.insert(
        'favorites',
        {
          'worker_id': worker['id'],
          'user_id': userId,
          'name': worker['name'] ?? '',
          'job_title': worker['job_title'] ?? '',
          'rating': worker['rating'] ?? 0.0,
          'distance': worker['distance'] ?? 0.0,
          'price': worker['price_per_hour'] ?? 0.0,
          'gender': worker['gender'] ?? '',
          'photo': worker['photo'] ?? '',
          'total_orders': worker['total_orders'] ?? 0,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      print('✅ Added favorite: worker_id=${worker['id']}, result=$result');
      return result > 0;
    } catch (e) {
      print('❌ Add favorite error: $e');
      return false;
    }
  }

  // ✅ FIXED: Remove favorite
  static Future<bool> removeFavorite(int workerId, int userId) async {
    try {
      final db = await database;
      final result = await db.delete(
        'favorites',
        where: 'worker_id = ? AND user_id = ?',
        whereArgs: [workerId, userId],
      );

      print('✅ Removed favorite: worker_id=$workerId, result=$result');
      return result > 0;
    } catch (e) {
      print('❌ Remove favorite error: $e');
      return false;
    }
  }

  // ✅ FIXED: Check if favorite
  static Future<bool> isFavorite(int workerId, int userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'favorites',
        where: 'worker_id = ? AND user_id = ?',
        whereArgs: [workerId, userId],
      );

      final isFav = result.isNotEmpty;
      print('🔍 Check favorite: worker_id=$workerId, is_favorite=$isFav');
      return isFav;
    } catch (e) {
      print('❌ Check favorite error: $e');
      return false;
    }
  }

  // ✅ Get all favorites
  static Future<List<Map<String, dynamic>>> getAllFavorites(int userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'favorites',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      print('📋 Get favorites: count=${result.length}');
      return result;
    } catch (e) {
      print('❌ Get favorites error: $e');
      return [];
    }
  }

  // ✅ Clear all favorites for user
  static Future<void> clearAllFavorites(int userId) async {
    try {
      final db = await database;
      await db.delete('favorites', where: 'user_id = ?', whereArgs: [userId]);
      print('🗑️ Cleared all favorites for user $userId');
    } catch (e) {
      print('❌ Clear favorites error: $e');
    }
  }

  // ✅ NEW: Debug method to see all data
  static Future<void> debugPrintAll() async {
    try {
      final db = await database;
      final result = await db.query('favorites');
      print('🔍 DEBUG - All favorites in database:');
      for (var row in result) {
        print('   $row');
      }
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }
}
