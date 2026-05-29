import 'package:flutter/material.dart';

enum ProductStatus { 
  free,
  occupied,
}

extension ProductStatusExtension on ProductStatus {
  String get stringValue => this == ProductStatus.free ? 'free' : 'occupied';
  
  String get displayName => this == ProductStatus.free ? 'Свободен' : 'Занят';
  
  Color get color => this == ProductStatus.free ? Colors.green : Colors.orange;
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.imageUrl,
    required this.status,
    this.takenByUserId,
    this.takenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String shortDescription;
  final String description;
  final String imageUrl;
  final ProductStatus status;
  final String? takenByUserId;
  final DateTime? takenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isFree => status == ProductStatus.free;
  bool get isOccupied => status == ProductStatus.occupied;

  Product copyWith({
    String? id,
    String? name,
    String? shortDescription,
    String? description,
    String? imageUrl,
    ProductStatus? status,
    String? takenByUserId,
    DateTime? takenAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      takenByUserId: takenByUserId ?? this.takenByUserId,
      takenAt: takenAt ?? this.takenAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ProductAction { taken, returned }

extension ProductActionExtension on ProductAction {
  String get stringValue => this == ProductAction.taken ? 'taken' : 'returned';
  
  String get displayName => this == ProductAction.taken ? 'Взял' : 'Вернул';
}

class ProductHistory {
  ProductHistory({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.timestamp,
  });

  final String id;
  final String productId;
  final String userId;
  final String userName;
  final ProductAction action;
  final DateTime timestamp;
}