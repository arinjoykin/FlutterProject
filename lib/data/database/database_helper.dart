import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'warehouse_app.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        short_description TEXT NOT NULL,
        description TEXT NOT NULL,
        image_url TEXT NOT NULL,
        status TEXT NOT NULL,
        taken_by_user_id TEXT,
        taken_at INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE product_history (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        user_name TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');

    await _createTestUsers(db);
  }

  Future<void> _createTestUsers(Database db) async {
    await db.insert('users', {
      'id': 'admin_001',
      'name': 'Администратор',
      'email': 'admin@example.com',
      'password_hash': 'admin123',
      'role': 'admin',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
    await db.insert('users', {
      'id': 'user_001',
      'name': 'Пользователь',
      'email': 'user@example.com',
      'password_hash': 'user123',
      'role': 'user',
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db
        .query('users', where: 'email = ?', whereArgs: [email.toLowerCase()]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert('users', user);
  }

  Future<bool> hasAnyUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.isNotEmpty;
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await database;
    return await db.query('products', orderBy: 'name ASC');
  }

  Future<Map<String, dynamic>?> getProductById(String id) async {
    final db = await database;
    final result = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<void> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.insert('products', product);
  }

  Future<void> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    await db.update('products', product,
        where: 'id = ?', whereArgs: [product['id']]);
  }

  Future<void> deleteProduct(String id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertHistory(Map<String, dynamic> history) async {
    final db = await database;
    await db.insert('product_history', history);
  }
}
