class PackageModel {
  final String id;
  final String name;
  final int quantity;
  final double price;
  final bool isActive;

  PackageModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.price,
    required this.isActive,
  });

  factory PackageModel.fromMap(
      Map<String, dynamic> map, String id) {
    return PackageModel(
      id: id,
      name: map['name'],
      quantity: map['quantity'],
      price: (map['price'] as num).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
      'isActive': isActive,
    };
  }
}
