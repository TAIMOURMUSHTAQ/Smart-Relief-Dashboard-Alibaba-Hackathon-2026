import 'dart:async';

import 'package:image_picker/image_picker.dart';

import '../models/inventory_item.dart';
import '../models/relief_request.dart';
import '../models/warehouse.dart';
import '../services/firestore_service.dart';

class DemoFirestoreService extends FirestoreService {
  static final _warehouse = Warehouse(
    id: 'wh-1',
    name: 'Karachi Central Warehouse',
    lat: 24.8607,
    lng: 67.0011,
    address: 'Karachi, Sindh, Pakistan',
  );

  static final _inventory = [
    InventoryItem(
      id: 'inv-1',
      warehouseId: 'wh-1',
      itemName: 'Rice (5kg bag)',
      category: 'Food',
      quantity: 500,
      unit: 'bags',
      lowStockThreshold: 100,
    ),
    InventoryItem(
      id: 'inv-2',
      warehouseId: 'wh-1',
      itemName: 'Flour (10kg bag)',
      category: 'Food',
      quantity: 350,
      unit: 'bags',
      lowStockThreshold: 80,
    ),
    InventoryItem(
      id: 'inv-3',
      warehouseId: 'wh-1',
      itemName: 'Drinking Water (19L)',
      category: 'Water',
      quantity: 200,
      unit: 'bottles',
      lowStockThreshold: 50,
    ),
    InventoryItem(
      id: 'inv-4',
      warehouseId: 'wh-1',
      itemName: 'Water Purification Tablets',
      category: 'Water',
      quantity: 45,
      unit: 'strips',
      lowStockThreshold: 50,
    ),
    InventoryItem(
      id: 'inv-5',
      warehouseId: 'wh-1',
      itemName: 'Paracetamol Tablets',
      category: 'Medicine',
      quantity: 120,
      unit: 'boxes',
      lowStockThreshold: 30,
    ),
    InventoryItem(
      id: 'inv-6',
      warehouseId: 'wh-1',
      itemName: 'First Aid Kit',
      category: 'Medicine',
      quantity: 80,
      unit: 'kits',
      lowStockThreshold: 20,
    ),
    InventoryItem(
      id: 'inv-7',
      warehouseId: 'wh-1',
      itemName: 'Family Tent',
      category: 'Shelter',
      quantity: 60,
      unit: 'units',
      lowStockThreshold: 15,
    ),
    InventoryItem(
      id: 'inv-8',
      warehouseId: 'wh-1',
      itemName: 'Blankets',
      category: 'Clothing',
      quantity: 300,
      unit: 'units',
      lowStockThreshold: 75,
    ),
  ];

  static final _requests = [
    ReliefRequest(
      id: 'req-1',
      volunteerId: 'demo-volunteer',
      areaName: 'Gulshan-e-Iqbal',
      lat: 24.9180,
      lng: 67.0971,
      headcount: 120,
      urgency: ReliefRequest.urgencyCritical,
      itemsNeeded: [
        RequestItem(itemName: 'Rice (5kg bag)', qty: 50),
        RequestItem(itemName: 'Drinking Water (19L)', qty: 30),
      ],
      status: ReliefRequest.statusPending,
      notes: 'Families displaced by flooding need immediate rations.',
      allocatedItems: [],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ReliefRequest(
      id: 'req-2',
      volunteerId: 'demo-volunteer',
      areaName: 'Malir Cantonment',
      lat: 24.9436,
      lng: 67.1883,
      headcount: 80,
      urgency: ReliefRequest.urgencyHigh,
      itemsNeeded: [
        RequestItem(itemName: 'First Aid Kit', qty: 20),
        RequestItem(itemName: 'Paracetamol Tablets', qty: 15),
      ],
      status: ReliefRequest.statusApproved,
      notes: 'Medical camp running low on supplies.',
      allocatedItems: [
        AllocatedItem(itemName: 'First Aid Kit', qty: 20, warehouseId: 'wh-1'),
        AllocatedItem(itemName: 'Paracetamol Tablets', qty: 15, warehouseId: 'wh-1'),
      ],
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    ReliefRequest(
      id: 'req-3',
      volunteerId: 'demo-volunteer',
      areaName: 'Clifton',
      lat: 24.8149,
      lng: 67.0360,
      headcount: 45,
      urgency: ReliefRequest.urgencyMedium,
      itemsNeeded: [RequestItem(itemName: 'Blankets', qty: 50)],
      status: ReliefRequest.statusInTransit,
      notes: 'Night temperatures dropping; blankets required.',
      allocatedItems: [AllocatedItem(itemName: 'Blankets', qty: 50, warehouseId: 'wh-1')],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ReliefRequest(
      id: 'req-4',
      volunteerId: 'demo-volunteer',
      areaName: 'Saddar',
      lat: 24.8615,
      lng: 67.0099,
      headcount: 200,
      urgency: ReliefRequest.urgencyHigh,
      itemsNeeded: [
        RequestItem(itemName: 'Family Tent', qty: 25),
        RequestItem(itemName: 'Rice (5kg bag)', qty: 100),
      ],
      status: ReliefRequest.statusPending,
      notes: 'Shelter needed for community center evacuees.',
      allocatedItems: [],
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
  ];

  @override
  Stream<List<Warehouse>> get warehousesStream => Stream.value([_warehouse]);

  @override
  Future<void> addWarehouse(Warehouse warehouse) async {}

  @override
  Stream<List<InventoryItem>> get inventoryStream => Stream.value(_inventory);

  @override
  Future<void> addInventoryItem(InventoryItem item) async {}

  @override
  Future<void> updateInventoryItem(InventoryItem item) async {}

  @override
  Future<void> deleteInventoryItem(String id) async {}

  @override
  Stream<List<ReliefRequest>> get allRequestsStream => Stream.value(_requests);

  @override
  Stream<List<ReliefRequest>> requestsForVolunteerStream(String volunteerId) =>
      Stream.value(_requests);

  @override
  Future<ReliefRequest?> getRequest(String id) async {
    return _requests.firstWhere((r) => r.id == id);
  }

  @override
  Future<void> addRequest(ReliefRequest request) async {}

  @override
  Future<void> updateRequestStatus(String id, String status) async {}

  @override
  Future<void> allocateStock({
    required String requestId,
    required List<AllocatedItem> allocations,
  }) async {}

  @override
  Future<String?> uploadRequestPhoto(XFile file) async => null;

  @override
  Future<void> seedInitialData() async {}
}
