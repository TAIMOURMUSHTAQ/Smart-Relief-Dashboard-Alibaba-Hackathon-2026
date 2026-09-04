import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/relief_request.dart';
import '../models/warehouse.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'request_detail_screen.dart';

class MapScreen extends StatelessWidget {
  final bool isAdmin;

  const MapScreen({super.key, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser?.uid;

    return Scaffold(
      body: StreamBuilder<List<ReliefRequest>>(
        stream: context.read<FirestoreService>().allRequestsStream,
        builder: (context, requestSnap) {
          return StreamBuilder<List<Warehouse>>(
            stream: context.read<FirestoreService>().warehousesStream,
            builder: (context, warehouseSnap) {
              final warehouses = warehouseSnap.data ?? [];
              final allRequests = requestSnap.data ?? [];
              final requests =
                  isAdmin
                      ? allRequests
                      : allRequests
                          .where((r) => r.volunteerId == userId)
                          .toList();
              final activeRequests = requests
                  .where((r) => r.status != ReliefRequest.statusDelivered)
                  .toList();

              return FlutterMap(
                options: const MapOptions(
                  initialCenter: LatLng(30.3753, 69.3451),
                  initialZoom: 6,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.relief_dashboard',
                  ),
                  MarkerLayer(
                    markers: [
                      ...warehouses.map(
                        (w) => Marker(
                          point: LatLng(w.lat, w.lng),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showWarehouseInfo(context, w),
                            child: const Icon(
                              Icons.warehouse,
                              color: AppTheme.primaryGreen,
                              size: 36,
                            ),
                          ),
                        ),
                      ),
                      ...activeRequests.map(
                        (r) => Marker(
                          point: LatLng(r.lat, r.lng),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showRequestInfo(context, r),
                            child: Icon(
                              Icons.location_pin,
                              color: AppTheme.urgencyColor(r.urgency),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showWarehouseInfo(BuildContext context, Warehouse warehouse) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warehouse.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(warehouse.address),
              ],
            ),
          ),
    );
  }

  void _showRequestInfo(BuildContext context, ReliefRequest request) {
    showModalBottomSheet(
      context: context,
      builder:
          (_) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.areaName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('${request.headcount} people • ${request.urgency}'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RequestDetailScreen(request: request),
                      ),
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ),
    );
  }
}
