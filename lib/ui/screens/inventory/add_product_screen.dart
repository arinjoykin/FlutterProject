import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/validators.dart';
import '../../../data/models/product.dart';
import '../../../logic/providers.dart';
import 'product_detail_screen.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});
  static const routeName = '/add-product';

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _shortCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _imagePicker = ImagePicker();
  ProductStatus _status = ProductStatus.free;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shortCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final product =
        await ref.read(addProductControllerProvider.notifier).submit(
              name: _nameCtrl.text,
              shortDescription: _shortCtrl.text,
              description: _descCtrl.text,
              imageUrl: _imageCtrl.text,
              status: _status,
            );

    if (product != null && mounted) {
      // ignore: use_build_context_synchronously
      Navigator.of(
        context,
      ).pushReplacementNamed(ProductDetailScreen.routeName, arguments: product);
    }
  }

  Future<void> _pickImageFromGallery() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _imageCtrl.text = file.path);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(addProductControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Добавить товар')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Название',
                          prefixIcon: Icon(Icons.inventory_2_outlined),
                        ),
                        validator: (v) =>
                            Validators.requiredField(v, fieldName: 'Название'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shortCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Краткое описание',
                          prefixIcon: Icon(Icons.notes_outlined),
                        ),
                        validator: (v) => Validators.requiredField(
                          v,
                          fieldName: 'Краткое описание',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          prefixIcon: Icon(Icons.description_outlined),
                        ),
                        validator: (v) =>
                            Validators.requiredField(v, fieldName: 'Описание'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Путь к изображению (необязательно)',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          onPressed: _pickImageFromGallery,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Выбрать фото из галереи'),
                        ),
                      ),
                      if (_imageCtrl.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _imageCtrl.text.startsWith('http')
                              ? Image.network(
                                  _imageCtrl.text,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(_imageCtrl.text),
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Статус:'),
                          const SizedBox(width: 12),
                          DropdownButton<ProductStatus>(
                            value: _status,
                            items: const [
                              DropdownMenuItem(
                                value: ProductStatus.free,
                                child: Text('Свободен'),
                              ),
                              DropdownMenuItem(
                                value: ProductStatus.occupied,
                                child: Text('Занят'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _status = v);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (state.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            state.errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: state.isSubmitting ? null : _submit,
                          icon: const Icon(Icons.add),
                          label: Text(
                            state.isSubmitting
                                ? 'Сохранение...'
                                : 'Создать товар',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
