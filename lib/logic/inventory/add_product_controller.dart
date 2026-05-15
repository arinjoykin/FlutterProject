import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

class AddProductState {
  const AddProductState({
    this.isSubmitting = false,
    this.errorMessage,
  });

  final bool isSubmitting;
  final String? errorMessage;

  AddProductState copyWith({
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return AddProductState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class AddProductController extends StateNotifier<AddProductState> {
  AddProductController(this._repo) : super(const AddProductState());
  final ProductRepository _repo;

  Future<Product?> submit({
    required String name,
    required String shortDescription,
    required String description,
    required String imageUrl,
    required ProductStatus status,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final product = await _repo.createProduct(
        name: name,
        shortDescription: shortDescription,
        description: description,
        imageUrl: imageUrl,
        status: status,
      );
      state = const AddProductState(isSubmitting: false);
      return product;
    } catch (_) {
      state = state.copyWith(
          isSubmitting: false, errorMessage: 'Не удалось создать товар');
      return null;
    }
  }
}
