// lib/sqlite/models.dart

class SQLiteCategory {
  final int? id;
  final String name;
  final String? description;

  SQLiteCategory({
    this.id,
    required this.name,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
    };
  }

  factory SQLiteCategory.fromMap(Map<String, dynamic> map) {
    return SQLiteCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String?,
    );
  }

  SQLiteCategory copyWith({int? id, String? name, String? description}) {
    return SQLiteCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }
}

class SQLiteProduct {
  final int? id;
  final String name;
  final double price;
  final int categoryId;
  final int stock;
  final DateTime createdAt;

  SQLiteProduct({
    this.id,
    required this.name,
    required this.price,
    required this.categoryId,
    required this.stock,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category_id': categoryId,
      'stock': stock,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SQLiteProduct.fromMap(Map<String, dynamic> map) {
    return SQLiteProduct(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: map['price'] as double,
      categoryId: map['category_id'] as int,
      stock: map['stock'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  SQLiteProduct copyWith({
    int? id,
    String? name,
    double? price,
    int? categoryId,
    int? stock,
    DateTime? createdAt,
  }) {
    return SQLiteProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      stock: stock ?? this.stock,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class SQLiteProductWithCategory {
  final SQLiteProduct product;
  final SQLiteCategory category;

  SQLiteProductWithCategory({
    required this.product,
    required this.category,
  });

  factory SQLiteProductWithCategory.fromMap(Map<String, dynamic> map) {
    return SQLiteProductWithCategory(
      product: SQLiteProduct(
        id: map['id'] as int?,
        name: map['name'] as String,
        price: map['price'] as double,
        categoryId: map['category_id'] as int,
        stock: map['stock'] as int,
        createdAt: DateTime.parse(map['created_at'] as String),
      ),
      category: SQLiteCategory(
        id: map['category_id'] as int?,
        name: map['category_name'] as String,
        description: map['category_description'] as String?,
      ),
    );
  }
}