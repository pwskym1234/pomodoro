class ShopItem {
  final int id;
  final String name;
  final int cost;
  final String description;

  ShopItem({
    required this.id,
    required this.name,
    required this.cost,
    required this.description,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      name: json['name'],
      cost: json['cost'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
      'description': description,
    };
  }
}
