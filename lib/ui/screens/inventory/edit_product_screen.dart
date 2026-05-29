import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user.dart';
import '../../../logic/providers.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  const EditProductScreen({super.key, required this.product});
  static const routeName = '/edit-product';

  final Product product;

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _shortCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _imageCtrl;
  final _imagePicker = ImagePicker();
  late ProductStatus _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _shortCtrl = TextEditingController(text: widget.product.shortDescription);
    _descCtrl = TextEditingController(text: widget.product.description);
    _imageCtrl = TextEditingController(text: widget.product.imageUrl);
    _status = widget.product.status;
  }

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
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // ИСПРАВЛЕНО: убрали .future
      final repo = ref.read(productRepositoryProvider);
      final updated = widget.product.copyWith(
        name: _nameCtrl.text.trim(),
        shortDescription: _shortCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        status: _status,
      );
      await repo.updateProduct(updated);
      if (mounted) {
        Navigator.of(context).pop(updated);
        ref.read(productListControllerProvider.notifier).load();
      }
    } catch (e) {
      setState(() {
        _error = 'Не удалось сохранить изменения';
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _imageCtrl.text = file.path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.currentUser?.role == UserRole.admin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать товар'),
        backgroundColor: isAdmin ? null : Colors.grey.shade700,
      ),
      body: isAdmin
          ? Center(
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
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Введите название'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _shortCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Краткое описание',
                                prefixIcon: Icon(Icons.notes_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Введите краткое описание'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descCtrl,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Описание',
                                prefixIcon: Icon(Icons.description_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Введите описание'
                                  : null,
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
                                    if (v != null) setState(() => _status = v);
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(_error!,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error)),
                              ),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _saving ? null : _submit,
                                icon: const Icon(Icons.save_outlined),
                                label: Text(_saving
                                    ? 'Сохранение...'
                                    : 'Сохранить изменения'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Доступ запрещен',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Только администраторы могут редактировать товары.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
