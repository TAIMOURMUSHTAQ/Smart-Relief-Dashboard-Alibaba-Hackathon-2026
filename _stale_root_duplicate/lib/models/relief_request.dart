import 'package:cloud_firestore/cloud_firestore.dart';

class RequestItem {
  final String itemName;
  final int qty;

  const RequestItem({required this.itemName, required this.qty});

  factory RequestItem.fromJson(Map<String, dynamic> json) {
    return RequestItem(
      itemName: json['itemName'] as String? ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'itemName': itemName, 'qty': qty};
  }
}

class AllocatedItem {
  final String itemName;
  final int qty;
  final String warehouseId;

  const AllocatedItem({
    required this.itemName,
    required this.qty,
    required this.warehouseId,
  });

  factory AllocatedItem.fromJson(Map<String, dynamic> json) {
    return AllocatedItem(
      itemName: json['itemName'] as String? ?? '',
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      warehouseId: json['warehouseId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'qty': qty,
      'warehouseId': warehouseId,
    };
  }
}

class ReliefRequest {
  final String? id;
  final String volunteerId;
  final String areaName;
  final double lat;
  final double lng;
  final int headcount;
  final String urgency;
  final List<RequestItem> itemsNeeded;
  final String status;
  final String notes;
  final String? photoUrl;
  final List<AllocatedItem> allocatedItems;
  final DateTime? createdAt;
  final DateTime? deliveredAt;

  const ReliefRequest({
    this.id,
    required this.volunteerId,
    required this.areaName,
    required this.lat,
    required this.lng,
    required this.headcount,
    required this.urgency,
    required this.itemsNeeded,
    required this.status,
    required this.notes,
    this.photoUrl,
    required this.allocatedItems,
    this.createdAt,
    this.deliveredAt,
  });

  factory ReliefRequest.fromJson(String id, Map<String, dynamic> json) {
    final createdRaw = json['createdAt'];
    final deliveredRaw = json['deliveredAt'];

    return ReliefRequest(
      id: id,
      volunteerId: json['volunteerId'] as String? ?? '',
      areaName: json['areaName'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      headcount: (json['headcount'] as num?)?.toInt() ?? 0,
      urgency: json['urgency'] as String? ?? 'Low',
      itemsNeeded: (json['itemsNeeded'] as List<dynamic>?)
              ?.map((e) => RequestItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      status: json['status'] as String? ?? 'Pending',
      notes: json['notes'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      allocatedItems: (json['allocatedItems'] as List<dynamic>?)
              ?.map((e) => AllocatedItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: createdRaw is Timestamp ? createdRaw.toDate() : null,
      deliveredAt: deliveredRaw is Timestamp ? deliveredRaw.toDate() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'volunteerId': volunteerId,
      'areaName': areaName,
      'lat': lat,
      'lng': lng,
      'headcount': headcount,
      'urgency': urgency,
      'itemsNeeded': itemsNeeded.map((e) => e.toJson()).toList(),
      'status': status,
      'notes': notes,
      'photoUrl': photoUrl,
      'allocatedItems': allocatedItems.map((e) => e.toJson()).toList(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (deliveredAt != null) 'deliveredAt': Timestamp.fromDate(deliveredAt!),
    };
  }

  ReliefRequest copyWith({
    String? id,
    String? volunteerId,
    String? areaName,
    double? lat,
    double? lng,
    int? headcount,
    String? urgency,
    List<RequestItem>? itemsNeeded,
    String? status,
    String? notes,
    String? photoUrl,
    List<AllocatedItem>? allocatedItems,
    DateTime? createdAt,
    DateTime? deliveredAt,
  }) {
    return ReliefRequest(
      id: id ?? this.id,
      volunteerId: volunteerId ?? this.volunteerId,
      areaName: areaName ?? this.areaName,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      headcount: headcount ?? this.headcount,
      urgency: urgency ?? this.urgency,
      itemsNeeded: itemsNeeded ?? this.itemsNeeded,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      photoUrl: photoUrl ?? this.photoUrl,
      allocatedItems: allocatedItems ?? this.allocatedItems,
      createdAt: createdAt ?? this.createdAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }

  static const String statusPending = 'Pending';
  static const String statusApproved = 'Approved';
  static const String statusInTransit = 'In Transit';
  static const String statusDelivered = 'Delivered';

  static const String urgencyCritical = 'Critical';
  static const String urgencyHigh = 'High';
  static const String urgencyMedium = 'Medium';
  static const String urgencyLow = 'Low';

  static const List<String> urgencyOrder = [
    urgencyCritical,
    urgencyHigh,
    urgencyMedium,
    urgencyLow,
  ];

  static const List<String> statuses = [
    statusPending,
    statusApproved,
    statusInTransit,
    statusDelivered,
  ];
}
