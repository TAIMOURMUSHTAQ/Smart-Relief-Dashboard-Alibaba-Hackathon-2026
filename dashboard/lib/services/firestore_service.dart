import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/inventory_item.dart';
import '../models/relief_request.dart';
import '../models/warehouse.dart';

class FirestoreService extends ChangeNotifier {
  FirestoreService({FirebaseFirestore? firestore, FirebaseStorage? storage})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _injectedStorage = storage;

  final FirebaseFirestore _firestore;
  final FirebaseStorage? _injectedStorage;

  // Lazy: only touches FirebaseStorage.instance (which requires a real
  // Firebase app) the first time a photo upload is actually attempted.
  FirebaseStorage get _storage => _injectedStorage ?? FirebaseStorage.instance;

  // Warehouses
  Stream<List<Warehouse>> get warehousesStream {
    return _firestore.collection('warehouses').snapshots().map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => Warehouse.fromJson(doc.id, doc.data()))
                  .toList(),
        );
  }

  Future<void> addWarehouse(Warehouse warehouse) async {
    await _firestore.collection('warehouses').add(warehouse.toJson());
  }

  // Inventory
  Stream<List<InventoryItem>> get inventoryStream {
    return _firestore.collection('inventory').snapshots().map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => InventoryItem.fromJson(doc.id, doc.data()))
                  .toList(),
        );
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    await _firestore.collection('inventory').add(item.toJson());
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    if (item.id == null) return;
    await _firestore.collection('inventory').doc(item.id).update(item.toJson());
  }

  Future<void> deleteInventoryItem(String id) async {
    await _firestore.collection('inventory').doc(id).delete();
  }

  // Requests
  Stream<List<ReliefRequest>> get allRequestsStream {
    return _firestore
        .collection('requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ReliefRequest.fromJson(doc.id, doc.data()))
                  .toList(),
        );
  }

  Stream<List<ReliefRequest>> requestsForVolunteerStream(String volunteerId) {
    return _firestore
        .collection('requests')
        .where('volunteerId', isEqualTo: volunteerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ReliefRequest.fromJson(doc.id, doc.data()))
                  .toList(),
        );
  }

  Future<ReliefRequest?> getRequest(String id) async {
    final doc = await _firestore.collection('requests').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return ReliefRequest.fromJson(doc.id, doc.data()!);
  }

  Future<void> addRequest(ReliefRequest request) async {
    await _firestore.collection('requests').add({
      ...request.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRequestStatus(String id, String status) async {
    final data = <String, dynamic>{'status': status};
    if (status == ReliefRequest.statusDelivered) {
      data['deliveredAt'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection('requests').doc(id).update(data);
  }

  Future<void> allocateStock({
    required String requestId,
    required List<AllocatedItem> allocations,
  }) async {
    await _firestore.runTransaction((transaction) async {
      for (final allocation in allocations) {
        final snapshot =
            await _firestore
                .collection('inventory')
                .where('warehouseId', isEqualTo: allocation.warehouseId)
                .where('itemName', isEqualTo: allocation.itemName)
                .limit(1)
                .get();

        if (snapshot.docs.isEmpty) {
          throw Exception('Inventory item not found for ${allocation.itemName}');
        }

        final doc = snapshot.docs.first;
        final currentQty = (doc.data()['quantity'] as num?)?.toInt() ?? 0;
        final newQty = currentQty - allocation.qty;

        if (newQty < 0) {
          throw Exception('Not enough stock for ${allocation.itemName}');
        }

        transaction.update(doc.reference, {'quantity': newQty});
      }

      transaction.update(_firestore.collection('requests').doc(requestId), {
        'allocatedItems': allocations.map((a) => a.toJson()).toList(),
        'status': ReliefRequest.statusApproved,
      });
    });
  }

  // Photo upload
  Future<String?> uploadRequestPhoto(XFile file) async {
    final ref = _storage.ref().child(
      'request_photos/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
    );
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await ref.putData(bytes);
    } else {
      await ref.putFile(File(file.path));
    }
    return await ref.getDownloadURL();
  }

  // Seed data
  Future<void> seedInitialData() async {
    final warehousesSnap = await _firestore.collection('warehouses').limit(1).get();
    if (warehousesSnap.docs.isNotEmpty) return;

    final warehouseRef = await _firestore.collection('warehouses').add({
      'name': 'Karachi Central Warehouse',
      'lat': 24.8607,
      'lng': 67.0011,
      'address': 'Karachi, Sindh, Pakistan',
    });

    final items = [
      InventoryItem(
        warehouseId: warehouseRef.id,
        itemName: 'Rice (5kg bag)',
        category: 'Food',
        quantity: 500,
        unit: 'bags',
        lowStockThreshold: 100,
      ),
      InventoryItem(
        warehouseId: warehouseRef.id,
        itemName: 'Flour (10kg bag)',
        category: 'Food',
        quantity: 350,
        unit: 'bags',
        lowStockThreshold: 80,
      ),
      InventoryItem(
        warehouseId: warehouseRef.id,
        itemName: 'Drinking Water (19L)',
        category: 'Water',
        quantity: 200,
        unit: 'bottles',
        lowStockThreshold: 50,
      ),
      InventoryItem(
        warehouseId: warehouseRef.id,
        itemName: 'Water Purification Tablets',
        category: 'Water',
        quantity: 45,
        unit: 'strips',
        lowStockThreshold: 50,
      ),
      InventoryItem(
        warehouseId: warehouseRef.id,
        itemName: 'Paracetamol Tablets',
        category: 'Medicine',
        quantity: 120,
        unit: 'boxes',
        lowStockThreshold: 30,
      ),
      InventoryItem(
        warehouseId: warehouseRef.id,
        itemName: 'First Aid Kit',
        category: 'Medicine',
        quantity: 80,
        unit: 'kits',
        lowStockThreshold: 20,
      ),
      InventoryItem(
        warehouseId: warehouseRef.id,
        itemName: 'Family Tent',
        category: 'Shelter',
        quantity: 60,
        unit: 'units',
        lowStockThreshold: 15,
      ),
      InventoryItem(
        warehouseId: warehouseRef.id,
        itemName: 'Blankets',
        category: 'Clothing',
        quantity: 300,
        unit: 'units',
        lowStockThreshold: 75,
      ),
    ];

    for (final item in items) {
      await _firestore.collection('inventory').add(item.toJson());
    }
  }
}
