// lib/drift/database.dart

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

// ========== TABLE DEFINITIONS ==========

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  TextColumn get description => text().nullable()();
}

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get categoryId => integer().references(Categories, #id, onDelete: KeyAction.cascade)();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ========== DATABASE CLASS ==========

@DriftDatabase(tables: [Categories, Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertSampleData();
      },
    );
  }

  Future<void> _insertSampleData() async {
    await into(categories).insert(
      CategoriesCompanion.insert(
        name: 'Electronics',
        description: const Value('Electronic devices'),
      ),
    );
    await into(categories).insert(
      CategoriesCompanion.insert(
        name: 'Books',
        description: const Value('Books and magazines'),
      ),
    );
    await into(categories).insert(
      CategoriesCompanion.insert(
        name: 'Clothing',
        description: const Value('Apparel and accessories'),
      ),
    );
  }

  // ========== CATEGORY OPERATIONS ==========

  Future<int> createCategory(CategoriesCompanion category) {
    return into(categories).insert(category);
  }

  Future<List<Category>> getAllCategories() {
    return (select(categories)..orderBy([(t) => OrderingTerm(expression: t.name)])).get();
  }

  Stream<List<Category>> watchAllCategories() {
    return (select(categories)..orderBy([(t) => OrderingTerm(expression: t.name)])).watch();
  }

  Future<Category?> getCategoryById(int id) {
    return (select(categories)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateCategory(Category category) {
    return update(categories).replace(category);
  }

  Future<int> deleteCategory(int id) {
    return (delete(categories)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteAllCategories() {
    return delete(categories).go();
  }

  // ========== PRODUCT OPERATIONS ==========

  Future<int> createProduct(ProductsCompanion product) {
    return into(products).insert(product);
  }

  Future<List<Product>> getAllProducts() {
    return (select(products)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .get();
  }

  Stream<List<Product>> watchAllProducts() {
    return (select(products)
      ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
        .watch();
  }

  Future<Product?> getProductById(int id) {
    return (select(products)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<bool> updateProduct(Product product) {
    return update(products).replace(product);
  }

  Future<int> deleteProduct(int id) {
    return (delete(products)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteAllProducts() {
    return delete(products).go();
  }

  Future<int> deleteProductsByCategory(int categoryId) {
    return (delete(products)..where((t) => t.categoryId.equals(categoryId))).go();
  }

  // ========== COMPLEX QUERIES ==========

  Future<List<ProductWithCategoryData>> getProductsWithCategory() {
    final query = select(products).join([
      innerJoin(categories, categories.id.equalsExp(products.categoryId))
    ]);

    return query.get().then((rows) {
      return rows.map((row) {
        return ProductWithCategoryData(
          product: row.readTable(products),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Stream<List<ProductWithCategoryData>> watchProductsWithCategory() {
    final query = select(products).join([
      innerJoin(categories, categories.id.equalsExp(products.categoryId))
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ProductWithCategoryData(
          product: row.readTable(products),
          category: row.readTable(categories),
        );
      }).toList();
    });
  }

  Future<List<Product>> getProductsByCategory(int categoryId) {
    return (select(products)
      ..where((t) => t.categoryId.equals(categoryId))
      ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();
  }

  Future<List<Product>> searchProducts(String query) {
    return (select(products)..where((t) => t.name.like('%$query%'))).get();
  }

  Future<Map<String, int>> getStockByCategory() async {
    final query = selectOnly(products)
      ..addColumns([categories.name, products.stock.sum()])
      ..join([innerJoin(categories, categories.id.equalsExp(products.categoryId))])
      ..groupBy([categories.name])
      ..orderBy([OrderingTerm(expression: products.stock.sum(), mode: OrderingMode.desc)]);

    final results = await query.get();
    return {
      for (var row in results)
        row.read(categories.name)!: row.read(products.stock.sum()) ?? 0
    };
  }

  Future<void> batchInsertProducts(List<ProductsCompanion> productList) async {
    await batch((batch) {
      batch.insertAll(products, productList);
    });
  }

  Future<void> transferStock(int fromProductId, int toProductId, int amount) async {
    await transaction(() async {
      final fromProduct = await getProductById(fromProductId);
      final toProduct = await getProductById(toProductId);

      if (fromProduct == null || toProduct == null) {
        throw Exception('Product not found');
      }

      if (fromProduct.stock < amount) {
        throw Exception('Insufficient stock');
      }

      await updateProduct(fromProduct.copyWith(stock: fromProduct.stock - amount));
      await updateProduct(toProduct.copyWith(stock: toProduct.stock + amount));
    });
  }

  Future<List<ProductStats>> getProductStats() {
    return customSelect(
      '''
      SELECT 
        c.name as category_name,
        COUNT(p.id) as product_count,
        AVG(p.price) as avg_price,
        SUM(p.stock) as total_stock
      FROM products p
      INNER JOIN categories c ON p.category_id = c.id
      GROUP BY c.id, c.name
      ORDER BY product_count DESC
      ''',
      readsFrom: {products, categories},
    ).map((row) {
      return ProductStats(
        categoryName: row.read<String>('category_name'),
        productCount: row.read<int>('product_count'),
        avgPrice: row.read<double>('avg_price'),
        totalStock: row.read<int>('total_stock'),
      );
    }).get();
  }

  // ========== UTILITY ==========

  Future<void> clearAllData() async {
    await delete(products).go();
    await delete(categories).go();
    await _insertSampleData();
  }

  Future<int> getProductCount() async {
    final query = selectOnly(products)..addColumns([products.id.count()]);
    final result = await query.getSingleOrNull();
    return result?.read(products.id.count()) ?? 0;
  }

  Future<int> getCategoryCount() async {
    final query = selectOnly(categories)..addColumns([categories.id.count()]);
    final result = await query.getSingleOrNull();
    return result?.read(categories.id.count()) ?? 0;
  }
}

// ========== HELPER CLASSES ==========

class ProductWithCategoryData {
  final Product product;
  final Category category;

  ProductWithCategoryData({required this.product, required this.category});
}

class ProductStats {
  final String categoryName;
  final int productCount;
  final double avgPrice;
  final int totalStock;

  ProductStats({
    required this.categoryName,
    required this.productCount,
    required this.avgPrice,
    required this.totalStock,
  });
}

// ========== CONNECTION ==========

QueryExecutor _openConnection() {
  return driftDatabase(name: 'products_drift');
}