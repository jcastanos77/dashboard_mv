class ServiceModel {
  final String id;
  final String name;
  final int dailyCapacity;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.name,
    required this.dailyCapacity,
    required this.isActive,
  });

  factory ServiceModel.fromMap(
      Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      name: map['name'],
      dailyCapacity: map['dailyCapacity'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dailyCapacity': dailyCapacity,
      'isActive': isActive,
    };
  }
}
