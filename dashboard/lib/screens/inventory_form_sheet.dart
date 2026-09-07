import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../models/warehouse.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class InventoryFormSheet extends StatefulWidget {
  final InventoryItem? item;
  final List<Warehouse> warehouses;

  const InventoryFormSheet({super.key, this.item, required this.warehouses});

  @override
  State<InventoryFormSheet> createState() => _InventoryFormSheetState();
}

class _InventoryFormSheetState extends State<InventoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _unitController = TextEditingController();
  final _thresholdController = TextEditingController();
  String _category = InventoryItem.categories.first;
  String? _warehouseId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _nameController.text = widget.item!.itemName;
      _quantityController.text = widget.item!.quantity.toString();
      _unitController.text = widget.item!.unit;
      _thresholdController.text = widget.item!.lowStockThreshold.toString();
      _category = widget.item!.category;
      _warehouseId = widget.item!.warehouseId;
    } else if (widget.warehouses.isNotEmpty) {
      _warehouseId = widget.warehouses.first.id;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_warehouseId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a warehouse')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final service = context.read<FirestoreService>();
      final item = InventoryItem(
        id: widget.item?.id,
        warehouseId: _warehouseId!,
        itemName: _nameController.text.trim(),
        category: _category,
        quantity: int.parse(_quantityController.text),
        unit: _unitController.text.trim(),
        lowStockThreshold: int.parse(_thresholdController.text),
      );

      if (widget.item == null) {
        await service.addInventoryItem(item);
      } else {
        await service.updateInventoryItem(item);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save item: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    if (widget.item?.id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete item?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.critical),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await context.read<FirestoreService>().deleteInventoryItem(
        widget.item!.id!,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete item: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Item' : 'Add Item',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Category'),
                items:
                    InventoryItem.categories
                        .map(
                          (c) => DropdownMenuItem(value: c, child: Text(c)),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _warehouseId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Warehouse'),
                items:
                    widget.warehouses
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _warehouseId = value);
                },
                validator: (value) {
                  if (value == null) return 'Select a warehouse';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      validator: (value) {
                        if (value == null || int.tryParse(value) == null) {
                          return 'Enter a number';
                        }
                        if (int.parse(value) < 0) return 'Must be >= 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        hintText: 'e.g. bags',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter unit';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _thresholdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Low Stock Threshold',
                ),
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Enter a number';
                  }
                  if (int.parse(value) < 0) return 'Must be >= 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
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
                        : Text(isEditing ? 'Save Changes' : 'Add Item'),
              ),
              if (isEditing) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _isLoading ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.critical,
                    side: const BorderSide(color: AppTheme.critical),
                  ),
                  child: const Text('Delete Item'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
