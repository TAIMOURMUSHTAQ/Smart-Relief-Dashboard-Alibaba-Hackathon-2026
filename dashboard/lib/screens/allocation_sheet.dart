import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../models/relief_request.dart';
import '../models/warehouse.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class AllocationSheet extends StatefulWidget {
  final ReliefRequest request;
  final List<InventoryItem> inventory;
  final List<Warehouse> warehouses;

  const AllocationSheet({
    super.key,
    required this.request,
    required this.inventory,
    required this.warehouses,
  });

  @override
  State<AllocationSheet> createState() => _AllocationSheetState();
}

class _AllocationSheetState extends State<AllocationSheet> {
  final Map<String, _AllocationChoice> _choices = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    for (final needed in widget.request.itemsNeeded) {
      final matching = widget.inventory.where(
        (i) => i.itemName == needed.itemName,
      );
      final warehouseId = matching.isNotEmpty ? matching.first.warehouseId : '';
      _choices[needed.itemName] = _AllocationChoice(
        itemName: needed.itemName,
        qty: needed.qty,
        warehouseId: warehouseId,
      );
    }
  }

  Future<void> _allocate() async {
    final allocations = _choices.values
        .where((c) => c.warehouseId.isNotEmpty && c.qty > 0)
        .map(
          (c) => AllocatedItem(
            itemName: c.itemName,
            qty: c.qty,
            warehouseId: c.warehouseId,
          ),
        )
        .toList();

    if (allocations.length != widget.request.itemsNeeded.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a warehouse and quantity for every item.'),
        ),
      );
      return;
    }

    for (final allocation in allocations) {
      final stock = widget.inventory
          .where(
            (i) =>
                i.warehouseId == allocation.warehouseId &&
                i.itemName == allocation.itemName,
          )
          .fold(0, (sum, i) => sum + i.quantity);

      if (allocation.qty > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Not enough ${allocation.itemName} at selected warehouse (available: $stock).',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      await context.read<FirestoreService>().allocateStock(
        requestId: widget.request.id!,
        allocations: allocations,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Allocation failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Allocate Stock',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Request: ${widget.request.areaName}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 20),
            ...widget.request.itemsNeeded.map((needed) {
              final choice = _choices[needed.itemName]!;
              final availableWarehouses = widget.warehouses.where((w) {
                return widget.inventory.any(
                  (i) => i.warehouseId == w.id && i.itemName == needed.itemName,
                );
              }).toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        needed.itemName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('alloc-${needed.itemName}-${choice.warehouseId}'),
                        initialValue:
                            choice.warehouseId.isEmpty
                                ? null
                                : choice.warehouseId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Warehouse',
                        ),
                        items:
                            availableWarehouses
                                .map(
                                  (w) => DropdownMenuItem(
                                    value: w.id,
                                    child: Text(w.name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _choices[needed.itemName] = choice.copyWith(
                              warehouseId: value ?? '',
                            );
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Select warehouse';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: choice.qty.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity to allocate',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _choices[needed.itemName] = choice.copyWith(
                              qty: int.tryParse(value) ?? 0,
                            );
                          });
                        },
                      ),
                      if (choice.warehouseId.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Available: ${_stockFor(choice.warehouseId, needed.itemName)}',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _allocate,
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Confirm Allocation'),
            ),
          ],
        ),
      ),
    );
  }

  int _stockFor(String warehouseId, String itemName) {
    return widget.inventory
        .where((i) => i.warehouseId == warehouseId && i.itemName == itemName)
        .fold(0, (sum, i) => sum + i.quantity);
  }
}

class _AllocationChoice {
  final String itemName;
  final int qty;
  final String warehouseId;

  _AllocationChoice({
    required this.itemName,
    required this.qty,
    required this.warehouseId,
  });

  _AllocationChoice copyWith({String? itemName, int? qty, String? warehouseId}) {
    return _AllocationChoice(
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
      warehouseId: warehouseId ?? this.warehouseId,
    );
  }
}
