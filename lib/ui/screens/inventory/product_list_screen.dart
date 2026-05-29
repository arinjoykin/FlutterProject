import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../logic/providers.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user.dart';
import '../../../logic/inventory/product_list_controller.dart';
import 'product_detail_screen.dart';
import 'add_product_screen.dart';
import '../qr/scan_qr_screen.dart';
import 'edit_product_screen.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});
  static const routeName = '/products';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productListControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.currentUser?.role == UserRole.admin;
    final sortTitle = state.sortOrder == ProductSortOrder.nameAsc
        ? 'Сортировка: А -> Я'
        : 'Сортировка: Я -> А';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Список товаров'),
        actions: [
          PopupMenuButton<ProductSortOrder>(
            tooltip: 'Сортировка',
            initialValue: state.sortOrder,
            onSelected: (value) {
              ref
                  .read(productListControllerProvider.notifier)
                  .setSortOrder(value);
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ProductSortOrder.nameAsc,
                child: Text('Название: А -> Я'),
              ),
              PopupMenuItem(
                value: ProductSortOrder.nameDesc,
                child: Text('Название: Я -> А'),
              ),
            ],
            icon: const Icon(Icons.sort_by_alpha),
          ),
          IconButton(
            tooltip: 'Сканировать QR',
            onPressed: () {
              Navigator.of(context).pushNamed(ScanQrScreen.routeName);
            },
            icon: const Icon(Icons.qr_code_scanner),
          ),
          if (isAdmin)
            IconButton(
              tooltip: 'Добавить товар',
              onPressed: () async {
                await Navigator.of(context).pushNamed(AddProductScreen.routeName);
                ref.read(productListControllerProvider.notifier).load();
              },
              icon: const Icon(Icons.add),
            ),
          PopupMenuButton<String>(
            tooltip: 'Профиль',
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authControllerProvider.notifier).logout();
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(authState.currentUser?.name ?? 'Пользователь'),
                    const SizedBox(height: 4),
                    Text(
                      authState.currentUser?.email ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Divider(),
                    Text(
                      isAdmin ? 'Администратор' : 'Пользователь',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isAdmin ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Выйти'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(productListControllerProvider.notifier).load(),
        child: Builder(
          builder: (context) {
            if (state.isLoading && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.errorMessage != null && state.items.isEmpty) {
              return Center(child: Text(state.errorMessage!));
            }
            if (state.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 52,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Список пуст. Добавьте первый товар.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.tune),
                    title: Text(sortTitle),
                    subtitle: Text('Всего товаров: ${state.items.length}'),
                  ),
                ),
                ...state.items.map((p) => _ProductListItem(product: p)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).pushNamed(AddProductScreen.routeName);
                ref.read(productListControllerProvider.notifier).load();
              },
              icon: const Icon(Icons.add),
              label: const Text('Добавить'),
            )
          : null,
    );
  }
}

class _ProductListItem extends StatelessWidget {
  const _ProductListItem({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final statusColor = product.status == ProductStatus.free ? Colors.green : Colors.orange;
    final statusText = product.status == ProductStatus.free ? 'Свободен' : 'Занят';
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.of(context).pushNamed(
            ProductDetailScreen.routeName,
            arguments: product,
          );
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: product.imageUrl.trim().isEmpty
                        ? Container(
                            width: 108,
                            height: 92,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image_not_supported),
                          )
                        : product.imageUrl.startsWith('http')
                            ? Image.network(
                                product.imageUrl,
                                width: 108,
                                height: 92,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 108,
                                  height: 92,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              )
                            : Image.file(
                                File(product.imageUrl),
                                width: 108,
                                height: 92,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 108,
                                  height: 92,
                                  color: Colors.grey.shade300,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Text(
                          statusText,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'ID: ${product.id.substring(0, 8)}...',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Consumer(
                builder: (context, ref, _) {
                  final authState = ref.watch(authControllerProvider);
                  final isAdmin = authState.currentUser?.role == UserRole.admin;
                  if (!isAdmin) return const SizedBox.shrink();
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Редактировать',
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            EditProductScreen.routeName,
                            arguments: product,
                          );
                        },
                      ),
                      IconButton(
                        tooltip: 'Удалить',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) {
                              return AlertDialog(
                                title: const Text('Удалить товар?'),
                                content: Text(
                                    'Вы действительно хотите удалить «${product.name}»?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(false),
                                    child: const Text('Отмена'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(ctx).pop(true),
                                    child: const Text('Удалить'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm == true) {
                            await ref
                                .read(productListControllerProvider.notifier)
                                .removeById(product.id);
                          }
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}