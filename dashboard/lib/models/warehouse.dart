class Warehouse {
  final String? id;
  final String name;
  final double lat;
  final double lng;
  final String address;

  const Warehouse({
    this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
  });

  factory Warehouse.fromJson(String id, Map<String, dynamic> json) {
    return Warehouse(
      id: id,
      name: json['name'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'lat': lat,
      'lng': lng,
      'address': address,
    };
  }
}
