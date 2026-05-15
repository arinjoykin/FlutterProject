import 'package:flutter/material.dart';
import 'core/styles/theme.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/inventory/product_list_screen.dart';
import 'ui/screens/inventory/product_detail_screen.dart';
import 'ui/screens/inventory/add_product_screen.dart';
import 'ui/screens/inventory/edit_product_screen.dart';
import 'ui/screens/qr/scan_qr_screen.dart';
import 'data/models/product.dart';

class WarehouseApp extends StatelessWidget {
	const WarehouseApp({super.key});

	@override
	Widget build(BuildContext context) {
		return MaterialApp(
			title: 'Warehouse',
			debugShowCheckedModeBanner: false,
			theme: buildWarehouseTheme(Brightness.light),
			darkTheme: buildWarehouseTheme(Brightness.dark),
			themeMode: ThemeMode.system,
			initialRoute: LoginScreen.routeName,
			routes: {
				LoginScreen.routeName: (_) => const LoginScreen(),
				RegisterScreen.routeName: (_) => const RegisterScreen(),
				ProductListScreen.routeName: (_) => const ProductListScreen(),
				AddProductScreen.routeName: (_) => const AddProductScreen(),
				EditProductScreen.routeName: (ctx) {
					final args = ModalRoute.of(ctx)!.settings.arguments;
					if (args is Product) return EditProductScreen(product: args);
					throw ArgumentError('EditProductScreen requires Product argument');
				},
				ScanQrScreen.routeName: (_) => const ScanQrScreen(),
			},
			onGenerateRoute: (settings) {
				if (settings.name == ProductDetailScreen.routeName) {
					final product = settings.arguments as Product;
					return MaterialPageRoute(
						builder: (_) => ProductDetailScreen(product: product),
					);
				}
				return null;
			},
		);
	}
}

