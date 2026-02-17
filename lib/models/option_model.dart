class OptionModel {
  final String id;
  final String name;
  final double extraCost;
  final bool isActive;

  OptionModel({
    required this.id,
    required this.name,
    required this.extraCost,
    required this.isActive,
  });

  factory OptionModel.fromMap(
      Map<String, dynamic> map, String id) {
    return OptionModel(
      id: id,
      name: map['name'],
      extraCost: (map['extraCost'] as num).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'extraCost': extraCost,
      'isActive': isActive,
    };
  }
}
