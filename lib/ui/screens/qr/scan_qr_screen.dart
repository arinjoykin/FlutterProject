import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../data/models/product.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../logic/providers.dart';
import '../../screens/inventory/product_detail_screen.dart';

class ScanQrScreen extends ConsumerStatefulWidget {
  const ScanQrScreen({super.key});
  static const routeName = '/scan-qr';

  @override
  ConsumerState<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends ConsumerState<ScanQrScreen> {
  String? _error;
  String? _raw;
  Map<String, dynamic>? _parsed;
  Product? _scannedProduct;
  bool _isProcessing = false;
  bool _handled = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_handled || _isProcessing) return;

    final codes = capture.barcodes;
    if (codes.isEmpty) return;

    final code = codes.first.rawValue ?? '';
    if (code.trim().isEmpty) {
      setState(() => _error = 'Пустые данные QR-кода');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
      _handled = true;
    });

    try {
      // Пытаемся распарсить JSON
      final map = jsonDecode(code) as Map<String, dynamic>;
      setState(() {
        _parsed = map;
        _raw = code;
      });

      if (map['type'] == 'product' && map['id'] is String) {
        await _processProduct(map['id']);
      } else {
        setState(() => _error = 'Неверный формат QR-кода товара');
      }
    } catch (_) {
      // Если не JSON, пробуем как ID товара
      setState(() {
        _raw = code;
      });
      await _processProduct(code);
    }

    setState(() => _isProcessing = false);
  }

  Future<void> _processProduct(String productId) async {
    final productRepo = await ref.read(productRepositoryProvider);
    final authState = ref.read(authControllerProvider);
    final currentUser = authState.currentUser;

    if (currentUser == null) {
      setState(() => _error = 'Пользователь не авторизован');
      return;
    }

    final product = await productRepo.getById(productId);

    if (product == null) {
      setState(() => _error = 'Товар не найден');
      return;
    }

    setState(() => _scannedProduct = product);

    // Определяем действие в зависимости от статуса товара
    if (product.isFree) {
      // Товар свободен - можно взять
      await _takeProduct(product, currentUser, productRepo);
    } else if (product.isOccupied) {
      // Товар занят - можно вернуть (если права позволяют)
      await _returnProduct(product, currentUser, productRepo);
    }
  }

  Future<void> _takeProduct(
      Product product, UserAccount user, ProductRepository repo) async {
    try {
      final updated = await repo.takeProduct(product.id, user);
      if (updated != null) {
        _showSuccessSnackBar('Товар "${product.name}" взят');
        setState(() => _scannedProduct = updated);
        // Обновляем список
        ref.read(productListControllerProvider.notifier).load();
      }
    } on ProductException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Ошибка при взятии товара');
    }
  }

  Future<void> _returnProduct(
      Product product, UserAccount user, ProductRepository repo) async {
    // Проверяем права: пользователь может вернуть только свой товар
    if (product.takenByUserId != user.id && user.role != UserRole.admin) {
      setState(() =>
          _error = 'Вы не можете вернуть товар, взятый другим пользователем');
      return;
    }

    try {
      final updated = await repo.returnProduct(product.id, user);
      if (updated != null) {
        _showSuccessSnackBar('Товар "${product.name}" возвращен');
        setState(() => _scannedProduct = updated);
        // Обновляем список
        ref.read(productListControllerProvider.notifier).load();
      }
    } on ProductException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Ошибка при возврате товара');
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _resetScanner() {
    setState(() {
      _handled = false;
      _error = null;
      _parsed = null;
      _scannedProduct = null;
      _raw = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканировать QR'),
        actions: [
          IconButton(
            onPressed: _resetScanner,
            icon: const Icon(Icons.refresh),
            tooltip: 'Новое сканирование',
          ),
        ],
      ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Text(
                        'Камера недоступна: ${error.errorCode.name}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: _buildResult(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline,
                      color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 8),
                  Text('Ошибка',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              if (_raw != null) ...[
                const SizedBox(height: 8),
                SelectableText('RAW: $_raw'),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _resetScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Сканировать снова'),
              ),
            ],
          ),
        ),
      );
    }

    if (_scannedProduct != null) {
      final product = _scannedProduct!;
      final isFree = product.isFree;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Результат сканирования',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  isFree ? Icons.check_circle : Icons.block,
                  color: isFree ? Colors.green : Colors.orange,
                ),
                title: Text(product.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(product.shortDescription),
              ),
              const Divider(),
              Row(
                children: [
                  Icon(
                    isFree ? Icons.inventory : Icons.person,
                    size: 16,
                    color: isFree ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isFree ? 'Товар доступен для взятия' : 'Товар занят',
                    style: TextStyle(
                      color: isFree ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (!isFree && product.takenAt != null) ...[
                const SizedBox(height: 4),
                Text('Взят: ${_formatDateTime(product.takenAt!)}'),
                if (product.takenByUserId != null)
                  Text(
                      'ID пользователя: ${product.takenByUserId!.substring(0, 8)}...'),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          ProductDetailScreen.routeName,
                          arguments: product,
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Подробнее'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _resetScanner,
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Сканировать'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Наведите камеру на QR-код товара',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Свободный товар → будет взят\nЗанятый товар → будет возвращен',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
