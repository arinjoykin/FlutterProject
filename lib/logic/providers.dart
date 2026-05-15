import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/product_repository.dart';
import 'auth/auth_controller.dart';
import 'inventory/product_list_controller.dart';
import 'inventory/add_product_controller.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
	return AuthRepository();
});

final productRepositoryProvider = Provider<ProductRepository>((ref) {
	return ProductRepository();
});

final authControllerProvider =
	StateNotifierProvider<AuthController, AuthState>((ref) {
	final repo = ref.watch(authRepositoryProvider);
	return AuthController(repo);
});

final productListControllerProvider = StateNotifierProvider<ProductListController, ProductListState>((ref) {
	final repo = ref.watch(productRepositoryProvider);
	return ProductListController(repo)..load();
});

final addProductControllerProvider = StateNotifierProvider<AddProductController, AddProductState>((ref) {
	final repo = ref.watch(productRepositoryProvider);
	return AddProductController(repo);
});
