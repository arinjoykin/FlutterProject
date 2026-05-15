import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';

enum ProductSortOrder { nameAsc, nameDesc }

class ProductListState {
  const ProductListState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.sortOrder = ProductSortOrder.nameAsc,
  });

  final List<Product> items;
  final bool isLoading;
  final String? errorMessage;
  final ProductSortOrder sortOrder;

  ProductListState copyWith({
    List<Product>? items,
    bool? isLoading,
    String? errorMessage,
    ProductSortOrder? sortOrder,
  }) {
    return ProductListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class ProductListController extends StateNotifier<ProductListState> {
  ProductListController(this._repo) : super(const ProductListState());

  final ProductRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = _sortItems(await _repo.fetchProducts(), state.sortOrder);
      state =
          state.copyWith(items: items, isLoading: false, errorMessage: null);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, errorMessage: 'Не удалось загрузить товары');
    }
  }

  Future<void> removeById(String id) async {
    try {
      await _repo.deleteProduct(id);
      final updated = List<Product>.from(state.items)
        ..removeWhere((p) => p.id == id);
      state = state.copyWith(items: updated);
    } catch (_) {}
  }

  void setSortOrder(ProductSortOrder order) {
    state = state.copyWith(
      sortOrder: order,
      items: _sortItems(List<Product>.from(state.items), order),
    );
  }

  List<Product> _sortItems(List<Product> items, ProductSortOrder order) {
    items.sort((a, b) {
      final compare = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return order == ProductSortOrder.nameAsc ? compare : -compare;
    });
    return items;
  }
}
