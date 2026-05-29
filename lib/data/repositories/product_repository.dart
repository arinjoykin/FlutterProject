import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/user.dart';
import '../../firestore_service.dart';

class ProductRepository {
  final dbHelper = DatabaseHelper.instance;
  final firestoreService = FirestoreService();

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
    final productId = const Uuid().v4();

    final product = {
      'id': productId,
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

    // Сохраняем в локальную SQLite БД
    await dbHelper.insertProduct(product);

    // Сохраняем в Firebase Firestore
    await firestoreService.saveProduct(productId, {
      'id': productId,
      'name': name.trim(),
      'shortDescription': shortDescription.trim(),
      'description': description.trim(),
      'imageUrl': imageUrl.trim(),
      'status': status.stringValue,
      'takenByUserId': null,
      'takenAt': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Товар сохранён в SQLite и Firebase: $name');

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

    // Обновляем в локальной SQLite БД
    await dbHelper.updateProduct(product);

    // Обновляем в Firebase Firestore
    await firestoreService.updateProduct(updated.id, {
      'name': updated.name,
      'shortDescription': updated.shortDescription,
      'description': updated.description,
      'imageUrl': updated.imageUrl,
      'status': updated.status.stringValue,
      'takenByUserId': updated.takenByUserId,
      'takenAt': updated.takenAt?.millisecondsSinceEpoch,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print('✅ Товар обновлён в SQLite и Firebase: ${updated.name}');

    return updated;
  }

  Future<void> deleteProduct(String id) async {
    // Удаляем из локальной SQLite БД
    await dbHelper.deleteProduct(id);

    // Удаляем из Firebase Firestore
    await firestoreService.deleteProduct(id);

    print('✅ Товар удалён из SQLite и Firebase: $id');
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

    // Обновляем в локальной SQLite БД
    await dbHelper.updateProduct(updatedProduct);

    // Обновляем в Firebase Firestore
    await firestoreService.updateProduct(productId, {
      'status': 'occupied',
      'takenByUserId': user.id,
      'takenAt': now,
      'updatedAt': FieldValue.serverTimestamp(),
    });

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
      throw ProductException(
          'Вы не можете вернуть товар, взятый другим пользователем');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedProduct = {
      ...product,
      'status': 'free',
      'taken_by_user_id': null,
      'taken_at': null,
      'updated_at': now,
    };

    // Обновляем в локальной SQLite БД
    await dbHelper.updateProduct(updatedProduct);

    // Обновляем в Firebase Firestore
    await firestoreService.updateProduct(productId, {
      'status': 'free',
      'takenByUserId': null,
      'takenAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Логируем действие
    await _addHistory(productId, user, 'returned');

    return _toProductModel(updatedProduct);
  }

  Future<void> _addHistory(
      String productId, UserAccount user, String action) async {
    final history = {
      'id': const Uuid().v4(),
      'product_id': productId,
      'user_id': user.id,
      'user_name': user.name,
      'action': action,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await dbHelper.insertHistory(history);

    // Сохраняем историю в Firebase
    await firestoreService.addHistory({
      'id': history['id'],
      'productId': productId,
      'userId': user.id,
      'userName': user.name,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Product _toProductModel(Map<String, dynamic> entity) {
    return Product(
      id: entity['id'] as String,
      name: entity['name'] as String,
      shortDescription: entity['short_description'] as String,
      description: entity['description'] as String,
      imageUrl: entity['image_url'] as String,
      status: entity['status'] == 'free'
          ? ProductStatus.free
          : ProductStatus.occupied,
      takenByUserId: entity['taken_by_user_id'],
      takenAt: entity['taken_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(entity['taken_at'] as int)
          : null,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(entity['created_at'] as int),
      updatedAt:
          DateTime.fromMillisecondsSinceEpoch(entity['updated_at'] as int),
    );
  }
}

class ProductException implements Exception {
  ProductException(this.message);
  final String message;
  @override
  String toString() => message;
}
