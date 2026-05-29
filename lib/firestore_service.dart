import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  late FirebaseFirestore firestore;

  Future<void> initialize() async {
    await Firebase.initializeApp();
    firestore = FirebaseFirestore.instance;
    print('✅ Firestore подключён!');
  }

  // Сохранить товар
  Future<void> saveProduct(String id, Map<String, dynamic> product) async {
    await firestore.collection('products').doc(id).set(product);
    print('📦 Товар сохранён в Firestore: $id');
  }

  // Обновить товар
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await firestore.collection('products').doc(id).update(data);
    print('📦 Товар обновлён в Firestore: $id');
  }

  // Удалить товар
  Future<void> deleteProduct(String id) async {
    await firestore.collection('products').doc(id).delete();
    print('📦 Товар удалён из Firestore: $id');
  }

  // Добавить историю
  Future<void> addHistory(Map<String, dynamic> history) async {
    await firestore.collection('history').add(history);
    print('📜 История сохранена в Firestore');
  }

  // Получить все товары (стрим)
  Stream<QuerySnapshot> getProducts() {
    return firestore.collection('products').snapshots();
  }

  // Получить один товар
  Future<DocumentSnapshot> getProduct(String id) async {
    return await firestore.collection('products').doc(id).get();
  }
}
