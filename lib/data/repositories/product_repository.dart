import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/user.dart';

class ProductRepository {
  final dbHelper = DatabaseHelper.instance;
  
  Future<List<Product>> fetchProducts() async {
    final products = await dbHelper.getAllProducts();
    return products.map(_toProductModel).toList();
  }
  
  Future<Product?> getById(String id) async {
    final product = await dbHelper.getProductById(id);
    return product != null ? _toProductModel(product) : null;
  }
  
  Future<Product> createProduct({
    required String name,
    required String shortDescription,
    required String description,
    required String imageUrl,
    ProductStatus status = ProductStatus.free,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final product = {
      'id': const Uuid().v4(),
      'name': name.trim(),
      'short_description': shortDescription.trim(),
      'description': description.trim(),
      'image_url': imageUrl.trim(),
      'status': status.stringValue,
      'taken_by_user_id': null,
      'taken_at': null,
      'created_at': now,
      'updated_at': now,
    };
    
    await dbHelper.insertProduct(product);
    return _toProductModel(product);
  }
  
  Future<Product> updateProduct(Product updated) async {
    final product = {
      'id': updated.id,
      'name': updated.name,
      'short_description': updated.shortDescription,
      'description': updated.description,
      'image_url': updated.imageUrl,
      'status': updated.status.stringValue,
      'taken_by_user_id': updated.takenByUserId,
      'taken_at': updated.takenAt?.millisecondsSinceEpoch,
      'created_at': updated.createdAt.millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
    
    await dbHelper.updateProduct(product);
    return updated;
  }
  
  Future<void> deleteProduct(String id) async {
    await dbHelper.deleteProduct(id);
  }
  
  Future<Product?> takeProduct(String productId, UserAccount user) async {
    final product = await dbHelper.getProductById(productId);
    
    if (product == null) {
      throw ProductException('Товар не найден');
    }
    
    if (product['status'] != 'free') {
      throw ProductException('Товар уже занят');
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedProduct = {
      ...product,
      'status': 'occupied',
      'taken_by_user_id': user.id,
      'taken_at': now,
      'updated_at': now,
    };
    
    await dbHelper.updateProduct(updatedProduct);
    
    // Логируем действие
    await _addHistory(productId, user, 'taken');
    
    return _toProductModel(updatedProduct);
  }
  
  Future<Product?> returnProduct(String productId, UserAccount user) async {
    final product = await dbHelper.getProductById(productId);
    
    if (product == null) {
      throw ProductException('Товар не найден');
    }
    
    if (product['status'] != 'occupied') {
      throw ProductException('Товар не был взят');
    }
    
    if (product['taken_by_user_id'] != user.id && user.role != UserRole.admin) {
      throw ProductException('Вы не можете вернуть товар, взятый другим пользователем');
    }
    
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedProduct = {
      ...product,
      'status': 'free',
      'taken_by_user_id': null,
      'taken_at': null,
      'updated_at': now,
    };
    
    await dbHelper.updateProduct(updatedProduct);
    
    // Логируем действие
    await _addHistory(productId, user, 'returned');
    
    return _toProductModel(updatedProduct);
  }
  
  Future<void> _addHistory(String productId, UserAccount user, String action) async {
    final history = {
      'id': const Uuid().v4(),
      'product_id': productId,
      'user_id': user.id,
      'user_name': user.name,
      'action': action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await dbHelper.insertHistory(history);
  }
  
  Product _toProductModel(Map<String, dynamic> entity) {
    return Product(
      id: entity['id'] as String,
      name: entity['name'] as String,
      shortDescription: entity['short_description'] as String,
      description: entity['description'] as String,
      imageUrl: entity['image_url'] as String,
      status: entity['status'] == 'free' ? ProductStatus.free : ProductStatus.occupied,
      takenByUserId: entity['taken_by_user_id'],
      takenAt: entity['taken_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(entity['taken_at'] as int)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(entity['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(entity['updated_at'] as int),
    );
  }
}

class ProductException implements Exception {
  ProductException(this.message);
  final String message;
  @override
  String toString() => message;
}