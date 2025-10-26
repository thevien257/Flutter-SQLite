// lib/screens/drift_screen.dart

import 'package:flutter/material.dart';
import '../drift/database.dart';
import 'package:drift/drift.dart' as drift;

class DriftScreen extends StatefulWidget {
  const DriftScreen({super.key});

  @override
  State<DriftScreen> createState() => _DriftScreenState();
}

class _DriftScreenState extends State<DriftScreen> {
  final AppDatabase _db = AppDatabase();

  @override
  void dispose() {
    _db.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drift Products (Reactive)'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () => _showCategoriesDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () => _confirmClearData(),
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => _showDatabaseInfo(),
          ),
        ],
      ),
      body: StreamBuilder<List<ProductWithCategoryData>>(
        stream: _db.watchProductsWithCategory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final products = snapshot.data!;
          return _buildProductList(products);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProductDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No products yet',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your first product',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text(
            '⚡ Drift uses reactive streams',
            style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(List<ProductWithCategoryData> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final item = products[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(item.category.name),
              child: Text(
                item.product.name[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              item.product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${item.category.name}'),
                Text('Stock: ${item.product.stock}'),
              ],
            ),
            trailing: Text(
              '\$${item.product.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            onTap: () => _showProductOptions(item),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Colors.blue;
      case 'books':
        return Colors.orange;
      case 'clothing':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showProductOptions(ProductWithCategoryData item) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                _showEditProductDialog(item.product);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Product'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteProduct(item.product);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddProductDialog() async {
    final categories = await _db.getAllCategories();

    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add categories first')),
      );
      return;
    }

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    int selectedCategoryId = categories.first.id;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (value) => selectedCategoryId = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all fields')),
                );
                return;
              }

              final product = ProductsCompanion.insert(
                name: nameController.text,
                price: double.parse(priceController.text),
                categoryId: selectedCategoryId,
                stock: drift.Value(int.parse(stockController.text)),
              );

              await _db.createProduct(product);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product added')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Product product) async {
    final categories = await _db.getAllCategories();
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stock.toString());
    int selectedCategoryId = product.categoryId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat.id,
                    child: Text(cat.name),
                  );
                }).toList(),
                onChanged: (value) => selectedCategoryId = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updated = product.copyWith(
                name: nameController.text,
                price: double.parse(priceController.text),
                stock: int.parse(stockController.text),
                categoryId: selectedCategoryId,
              );

              await _db.updateProduct(updated);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product updated')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db.deleteProduct(product.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Product deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCategoriesDialog() async {
    final categories = await _db.getAllCategories();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Categories'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                title: Text(cat.name),
                subtitle: Text(cat.description ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCategory(cat),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddCategoryDialog();
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final category = CategoriesCompanion.insert(
                name: nameController.text,
                description: drift.Value(descController.text),
              );

              await _db.createCategory(category);
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(Category category) async {
    await _db.deleteCategory(category.id);
  }

  void _confirmClearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all products and reset categories.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _db.clearAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data cleared')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDatabaseInfo() async {
    final productCount = await _db.getProductCount();
    final categoryCount = await _db.getCategoryCount();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Products: $productCount'),
            Text('Categories: $categoryCount'),
            const SizedBox(height: 16),
            const Text('Path:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Text('products_drift.sqlite', style: TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            const Text(
              '⚡ Drift Features:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• Type-safe queries'),
            const Text('• Reactive streams'),
            const Text('• Auto-generated code'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}