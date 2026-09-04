import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../models/relief_request.dart';
import '../models/warehouse.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/status_badge.dart';
import '../widgets/urgency_badge.dart';
import 'allocation_sheet.dart';
import 'request_detail_screen.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  String _statusFilter = 'All';

  List<ReliefRequest> _sortRequests(List<ReliefRequest> requests) {
    return requests
      ..sort((a, b) {
        final urgencyCompare = ReliefRequest.urgencyOrder.indexOf(a.urgency) -
            ReliefRequest.urgencyOrder.indexOf(b.urgency);
        if (urgencyCompare != 0) return urgencyCompare;
        return (b.createdAt ?? DateTime(0)).compareTo(
          a.createdAt ?? DateTime(0),
        );
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<ReliefRequest>>(
        stream: context.read<FirestoreService>().allRequestsStream,
        builder: (context, requestSnap) {
          return StreamBuilder<List<InventoryItem>>(
            stream: context.read<FirestoreService>().inventoryStream,
            builder: (context, inventorySnap) {
              return StreamBuilder<List<Warehouse>>(
                stream: context.read<FirestoreService>().warehousesStream,
                builder: (context, warehouseSnap) {
                  if (requestSnap.connectionState == ConnectionState.waiting ||
                      inventorySnap.connectionState ==
                          ConnectionState.waiting ||
                      warehouseSnap.connectionState ==
                          ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final requests = requestSnap.data ?? [];
                  final inventory = inventorySnap.data ?? [];
                  final warehouses = warehouseSnap.data ?? [];

                  final filtered =
                      _statusFilter == 'All'
                          ? requests
                          : requests
                              .where((r) => r.status == _statusFilter)
                              .toList();
                  final sorted = _sortRequests(filtered);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children:
                                ['All', ...ReliefRequest.statuses].map((status) {
                              final selected = _statusFilter == status;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(status),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() => _statusFilter = status);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            sorted.isEmpty
                                ? const Center(
                                  child: Text('No requests match this filter.'),
                                )
                                : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  itemCount: sorted.length,
                                  itemBuilder: (context, index) {
                                    final request = sorted[index];
                                    return _RequestCard(
                                      request: request,
                                      inventory: inventory,
                                      warehouses: warehouses,
                                    );
                                  },
                                ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ReliefRequest request;
  final List<InventoryItem> inventory;
  final List<Warehouse> warehouses;

  const _RequestCard({
    required this.request,
    required this.inventory,
    required this.warehouses,
  });

  Future<void> _advanceStatus(BuildContext context) async {
    String nextStatus;
    switch (request.status) {
      case ReliefRequest.statusPending:
      case ReliefRequest.statusApproved:
        nextStatus = ReliefRequest.statusInTransit;
        break;
      case ReliefRequest.statusInTransit:
        nextStatus = ReliefRequest.statusDelivered;
        break;
      default:
        return;
    }

    await context.read<FirestoreService>().updateRequestStatus(
      request.id!,
      nextStatus,
    );
  }

  void _openAllocation(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return AllocationSheet(
          request: request,
          inventory: inventory,
          warehouses: warehouses,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAllocate =
        request.status == ReliefRequest.statusPending ||
        request.status == ReliefRequest.statusApproved;
    final canAdvance =
        request.status == ReliefRequest.statusApproved ||
        request.status == ReliefRequest.statusInTransit;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RequestDetailScreen(request: request),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.areaName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  UrgencyBadge(urgency: request.urgency),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatusBadge(status: request.status),
                  const SizedBox(width: 12),
                  Text('${request.headcount} people'),
                  const SizedBox(width: 12),
                  Text('${request.itemsNeeded.length} items'),
                ],
              ),
              if (request.createdAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Submitted: ${_formatDate(request.createdAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (canAllocate)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openAllocation(context),
                        child: const Text('Allocate Stock'),
                      ),
                    ),
                  if (canAllocate && canAdvance) const SizedBox(width: 12),
                  if (canAdvance)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _advanceStatus(context),
                        child: Text(
                          request.status == ReliefRequest.statusApproved
                              ? 'Mark In Transit'
                              : 'Mark Delivered',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
