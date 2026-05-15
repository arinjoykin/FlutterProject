import 'package:uuid/uuid.dart';
import '../models/product.dart';

class ProductRepository {
  ProductRepository();

  final Map<String, Product> _idToProduct = {};
  final _uuid = const Uuid();

  Future<List<Product>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _idToProduct.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<Product?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _idToProduct[id];
  }

  Future<Product> createProduct({
    required String name,
    required String shortDescription,
    required String description,
    required String imageUrl,
    ProductStatus status = ProductStatus.free,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final id = _uuid.v4();
    final product = Product(
      id: id,
      name: name.trim(),
      shortDescription: shortDescription.trim(),
      description: description.trim(),
      imageUrl: imageUrl.trim(),
      status: status,
    );
    _idToProduct[id] = product;
    return product;
  }

  Future<Product> updateProduct(Product updated) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _idToProduct[updated.id] = updated;
    return updated;
  }

  Future<void> deleteProduct(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _idToProduct.remove(id);
  }
}
