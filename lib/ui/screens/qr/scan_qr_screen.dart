import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../logic/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  bool _handled = false;
  int? _agentParsedLayoutLogKey;

  static const _agentLogPath = r'd:\PROJECTS\FlutterProjects\debug-4a1361.log';

  void _agentNdjson(String hypothesisId, String location, String message,
      Map<String, Object?> data,
      {String runId = 'post-expand-wrap'}) {
    if (!kDebugMode) return;
    try {
      File(_agentLogPath).writeAsStringSync(
        '${jsonEncode({
              'sessionId': '4a1361',
              'hypothesisId': hypothesisId,
              'location': location,
              'message': message,
              'data': data,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'runId': runId,
            })}\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    final codes = capture.barcodes;
    if (codes.isEmpty) return;
    final code = codes.first.rawValue ?? '';
    if (code.trim().isEmpty) {
      setState(() => _error = 'Пустые данные QR-кода');
      return;
    }
    try {
      final map = jsonDecode(code) as Map<String, dynamic>;
      setState(() {
        _parsed = map;
        _raw = code;
        _error = null;
        _handled = true;
      });
    } catch (_) {
      final repo = ref.read(productRepositoryProvider);
      try {
        final product = await repo.getById(code);
        if (product != null) {
          setState(() {
            _parsed = {
              'type': 'product',
              'id': product.id,
              'name': product.name,
            };
            _raw = code;
            _error = null;
            _handled = true;
          });
        } else {
          setState(() {
            _raw = code;
            _error = 'Некорректный QR или товар не найден';
            _handled = true;
          });
        }
      } catch (_) {
        setState(() {
          _raw = code;
          _error = 'Ошибка обработки QR';
          _handled = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканировать QR')),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Builder(
              builder: (context) {
                return MobileScanner(
                  onDetect: _onDetect,
                  errorBuilder: (context, error, child) {
                    return Center(
                      child: Text(
                        'Камера недоступна: ${error.errorCode.name}',
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildResult(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    if (_error != null) {
      return Card(
        child: SizedBox.expand(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ошибка', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                        if (_raw != null) ...[
                          const SizedBox(height: 8),
                          SelectableText('RAW: $_raw'),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (_parsed != null) {
      final jsonStr = const JsonEncoder.withIndent('  ').convert(_parsed);
      return LayoutBuilder(
        builder: (context, constraints) {
          // #region agent log
          final logKey = Object.hash(jsonStr.hashCode, _raw?.length ?? 0,
              constraints.maxHeight.round());
          if (_agentParsedLayoutLogKey != logKey) {
            _agentParsedLayoutLogKey = logKey;
            final mq = MediaQuery.sizeOf(context);
            _agentNdjson('B', 'scan_qr_screen:_buildResult',
                'parsed_result_constraints', {
              'maxHeight': constraints.maxHeight,
              'maxWidth': constraints.maxWidth,
              'screenH': mq.height,
              'screenW': mq.width,
              'rawLen': _raw?.length ?? 0,
              'jsonChars': jsonStr.length,
              'sizedBoxExpand': true,
              'actionsWrap': true,
            });
          }
          return Card(
            child: SizedBox.expand(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Данные QR',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText(jsonStr),
                            if (_raw != null) ...[
                              const SizedBox(height: 8),
                              SelectableText('RAW: $_raw'),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _handled = false;
                              _error = null;
                              _parsed = null;
                              _raw = null;
                              _agentParsedLayoutLogKey = null;
                            });
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Сканировать снова'),
                        ),
                        if (_parsed?['type'] == 'product' &&
                            _parsed?['id'] is String)
                          FilledButton.tonalIcon(
                            onPressed: () async {
                              final id = _parsed!['id'] as String;
                              final repo = ref.read(productRepositoryProvider);
                              final product = await repo.getById(id);
                              if (product != null && context.mounted) {
                                Navigator.of(context).pushNamed(
                                  ProductDetailScreen.routeName,
                                  arguments: product,
                                );
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Товар не найден')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Открыть товар'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    return Center(
      child: Text(
        'Наведите камеру на QR-код',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}
