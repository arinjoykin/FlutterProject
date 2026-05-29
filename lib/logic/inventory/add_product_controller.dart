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

  factory AddProductController.fromFuture(Future<ProductRepository> repoFuture) {
    final controller = AddProductController._(null);
    repoFuture.then((repo) {
      controller._repo = repo;
    }).catchError((error) {
      controller.state = controller.state.copyWith(
        errorMessage: 'Ошибка загрузки базы данных',
      );
    });
    return controller;
  }

  AddProductController._(ProductRepository? repo) : _repo = repo, super(const AddProductState());

  ProductRepository? _repo;

  Future<Product?> submit({
    required String name,
    required String shortDescription,
    required String description,
    required String imageUrl,
    required ProductStatus status,
  }) async {
    if (_repo == null) {
      state = state.copyWith(errorMessage: 'База данных не инициализирована');
      return null;
    }
    
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final product = await _repo!.createProduct(
        name: name,
        shortDescription: shortDescription,
        description: description,
        imageUrl: imageUrl,
        status: status,
      );
      state = const AddProductState(isSubmitting: false);
      return product;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Не удалось создать товар',
      );
      return null;
    }
  }
}