enum ProductStatus { free, occupied }

class Product {
	Product({
		required this.id,
		required this.name,
		required this.shortDescription,
		required this.description,
		required this.imageUrl,
		required this.status,
	});

	final String id;
	final String name;
	final String shortDescription;
	final String description;
	final String imageUrl;
	final ProductStatus status;

	Product copyWith({
		String? id,
		String? name,
		String? shortDescription,
		String? description,
		String? imageUrl,
		ProductStatus? status,
	}) {
		return Product(
			id: id ?? this.id,
			name: name ?? this.name,
			shortDescription: shortDescription ?? this.shortDescription,
			description: description ?? this.description,
			imageUrl: imageUrl ?? this.imageUrl,
			status: status ?? this.status,
		);
	}
}

