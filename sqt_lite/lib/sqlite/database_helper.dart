// lib/sqlite/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('products.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category_id INTEGER NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_products_category ON products(category_id)');
    await db.execute('CREATE INDEX idx_products_name ON products(name)');

    await _insertSampleData(db);
  }

  Future _insertSampleData(Database db) async {
    await db.insert('categories', {'name': 'Electronics', 'description': 'Electronic devices'});
    await db.insert('categories', {'name': 'Books', 'description': 'Books and magazines'});
    await db.insert('categories', {'name': 'Clothing', 'description': 'Apparel and accessories'});
  }

  // ========== CATEGORY CRUD ==========

  Future<SQLiteCategory> createCategory(SQLiteCategory category) async {
    final db = await database;
    final id = await db.insert('categories', category.toMap());
    return category.copyWith(id: id);
  }

  Future<List<SQLiteCategory>> readAllCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((map) => SQLiteCategory.fromMap(map)).toList();
  }

  Future<SQLiteCategory?> readCategory(int id) async {
    final db = await database;
    final maps = await db.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SQLiteCategory.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(SQLiteCategory category) async {
    final db = await database;
    return db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllCategories() async {
    final db = await database;
    return await db.delete('categories');
  }

  // ========== PRODUCT CRUD ==========

  Future<SQLiteProduct> createProduct(SQLiteProduct product) async {
    final db = await database;
    final id = await db.insert('products', product.toMap());
    return product.copyWith(id: id);
  }

  Future<List<SQLiteProduct>> readAllProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'created_at DESC');
    return result.map((map) => SQLiteProduct.fromMap(map)).toList();
  }

  Future<SQLiteProduct?> readProduct(int id) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return SQLiteProduct.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateProduct(SQLiteProduct product) async {
    final db = await database;
    return db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllProducts() async {
    final db = await database;
    return await db.delete('products');
  }

  Future<int> deleteProductsByCategory(int categoryId) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // ========== COMPLEX QUERIES ==========

  Future<List<SQLiteProductWithCategory>> getProductsWithCategory() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        p.id, p.name, p.price, p.category_id, p.stock, p.created_at,
        c.name as category_name,
        c.description as category_description
      FROM products p
      INNER JOIN categories c ON p.category_id = c.id
      ORDER BY p.created_at DESC
    ''');

    return result.map((map) => SQLiteProductWithCategory.fromMap(map)).toList();
  }

  Future<List<SQLiteProduct>> getProductsByCategory(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'name ASC',
    );
    return result.map((map) => SQLiteProduct.fromMap(map)).toList();
  }

  Future<List<SQLiteProduct>> searchProducts(String query) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
    );
    return result.map((map) => SQLiteProduct.fromMap(map)).toList();
  }

  Future<Map<String, int>> getStockByCategory() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT c.name, SUM(p.stock) as total_stock
      FROM products p
      INNER JOIN categories c ON p.category_id = c.id
      GROUP BY c.id, c.name
      ORDER BY total_stock DESC
    ''');

    return {
      for (var row in result)
        row['name'] as String: row['total_stock'] as int
    };
  }

  Future<void> batchInsertProducts(List<SQLiteProduct> products) async {
    final db = await database;
    final batch = db.batch();

    for (var product in products) {
      batch.insert('products', product.toMap());
    }

    await batch.commit(noResult: true);
  }

  // ========== UTILITY ==========

  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'products.db');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('products');
    await db.delete('categories');
    await _insertSampleData(db);
  }

  Future<int> getProductCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getCategoryCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future close() async {
    final db = await database;
    db.close();
  }
}