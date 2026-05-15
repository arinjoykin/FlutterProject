import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../data/models/product.dart';
import '../../../logic/providers.dart';
import 'edit_product_screen.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.product});
  static const routeName = '/product';

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor =
        product.status == ProductStatus.free ? Colors.green : Colors.orange;
    final statusText =
        product.status == ProductStatus.free ? 'Свободен' : 'Занят';
    final qrPayload = jsonEncode({
      'type': 'product',
      'id': product.id,
      'name': product.name,
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            tooltip: 'Редактировать',
            onPressed: () {
              Navigator.of(context).pushNamed(
                EditProductScreen.routeName,
                arguments: product,
              );
            },
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: 'Удалить',
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
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Отмена'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Удалить'),
                      ),
                    ],
                  );
                },
              );
              if (confirm == true) {
                await ref
                    .read(productRepositoryProvider)
                    .deleteProduct(product.id);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop(); // close detail
                // trigger list refresh if present
                ref.read(productListControllerProvider.notifier).load();
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 3 / 2,
                  child: product.imageUrl.trim().isEmpty
                      ? Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        )
                      : product.imageUrl.startsWith('http')
                          ? Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            )
                          : Image.file(
                              File(product.imageUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Chip(
                        avatar:
                            Icon(Icons.circle, size: 10, color: statusColor),
                        label: Text(statusText),
                      ),
                      Chip(
                        avatar: const Icon(Icons.qr_code_2, size: 16),
                        label: Text('ID: ${product.id.substring(0, 10)}...'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QR-код товара',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: QrImageView(
                      data: qrPayload,
                      version: QrVersions.auto,
                      size: 220,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    product.id,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
