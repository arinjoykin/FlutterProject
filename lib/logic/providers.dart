import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/product_repository.dart';
import 'auth/auth_controller.dart';
import 'inventory/product_list_controller.dart';
import 'inventory/add_product_controller.dart';

// Провайдер для AuthRepository (теперь синхронный!)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Провайдер для ProductRepository
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

// Провайдер для AuthController
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

final productListControllerProvider =
    StateNotifierProvider<ProductListController, ProductListState>((ref) {
  final repo = ProductRepository(); // <--- СИНХРОННО, НЕ Future
  return ProductListController(repo)..load();
});

// Провайдер для AddProductController
final addProductControllerProvider =
    StateNotifierProvider<AddProductController, AddProductState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return AddProductController(repo);
});
