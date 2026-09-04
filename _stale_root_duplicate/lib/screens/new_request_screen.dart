import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/inventory_item.dart';
import '../models/relief_request.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class NewRequestScreen extends StatefulWidget {
  const NewRequestScreen({super.key});

  @override
  State<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends State<NewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();
  final _latController = TextEditingController(text: '24.8607');
  final _lngController = TextEditingController(text: '67.0011');
  final _headcountController = TextEditingController();
  final _notesController = TextEditingController();
  String _urgency = ReliefRequest.urgencyMedium;
  final List<_ItemNeed> _itemsNeeded = [];
  XFile? _photo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _itemsNeeded.add(const _ItemNeed(itemName: '', qty: 1));
  }

  Future<void> _getLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permissions are permanently denied. Please enable them in settings.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lngController.text = position.longitude.toStringAsFixed(6);
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not get location: $e')));
      }
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => _photo = photo);
    }
  }

  Future<void> _submit(List<InventoryItem> inventory) async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    if (authService.currentUser == null) return;

    final items = _itemsNeeded
        .where((i) => i.itemName.isNotEmpty && i.qty > 0)
        .map(
          (i) => RequestItem(itemName: i.itemName, qty: i.qty),
        )
        .toList();

    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one needed item.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final firestore = context.read<FirestoreService>();
      String? photoUrl;
      if (_photo != null) {
        photoUrl = await firestore.uploadRequestPhoto(_photo!);
      }

      final request = ReliefRequest(
        volunteerId: authService.currentUser!.uid,
        areaName: _areaController.text.trim(),
        lat: double.parse(_latController.text),
        lng: double.parse(_lngController.text),
        headcount: int.parse(_headcountController.text),
        urgency: _urgency,
        itemsNeeded: items,
        status: ReliefRequest.statusPending,
        notes: _notesController.text.trim(),
        photoUrl: photoUrl,
        allocatedItems: const [],
      );

      await firestore.addRequest(request);

      if (mounted) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully')),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit request: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resetForm() {
    _areaController.clear();
    _headcountController.clear();
    _notesController.clear();
    _latController.text = '24.8607';
    _lngController.text = '67.0011';
    _urgency = ReliefRequest.urgencyMedium;
    _photo = null;
    _itemsNeeded.clear();
    _itemsNeeded.add(const _ItemNeed(itemName: '', qty: 1));
  }

  @override
  void dispose() {
    _areaController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _headcountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<InventoryItem>>(
        stream: context.read<FirestoreService>().inventoryStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final inventory = snapshot.data ?? [];
          final itemNames = inventory.map((i) => i.itemName).toSet().toList()
            ..sort();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'New Relief Request',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _areaController,
                    decoration: const InputDecoration(
                      labelText: 'Affected Area Name',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter area name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _latController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Lat'),
                          validator: (value) {
                            if (value == null ||
                                double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lngController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Lng'),
                          validator: (value) {
                            if (value == null ||
                                double.tryParse(value) == null) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        onPressed: _getLocation,
                        icon: const Icon(Icons.my_location),
                        tooltip: 'Use my location',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _headcountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'People Count',
                    ),
                    validator: (value) {
                      if (value == null || int.tryParse(value) == null) {
                        return 'Enter a number';
                      }
                      if (int.parse(value) <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Urgency',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments:
                            ReliefRequest.urgencyOrder
                                .map(
                                  (u) => ButtonSegment(
                                    value: u,
                                    label: Text(u),
                                  ),
                                )
                                .toList(),
                        selected: {_urgency},
                        onSelectionChanged: (selection) {
                          setState(() => _urgency = selection.first);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Items Needed',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._itemsNeeded.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            key: ValueKey('item-$index-${item.itemName}'),
                            initialValue:
                                item.itemName.isEmpty ? null : item.itemName,
                            decoration: const InputDecoration(
                              labelText: 'Item',
                            ),
                            items:
                                itemNames
                                    .map(
                                      (name) => DropdownMenuItem(
                                        value: name,
                                        child: Text(name),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              setState(() {
                                _itemsNeeded[index] = _itemsNeeded[index]
                                    .copyWith(itemName: value ?? '');
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Select item';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.qty.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                            ),
                            onChanged: (value) {
                              setState(() {
                                _itemsNeeded[index] = _itemsNeeded[index]
                                    .copyWith(
                                      qty: int.tryParse(value) ?? 0,
                                    );
                              });
                            },
                            validator: (value) {
                              if (value == null ||
                                  int.tryParse(value) == null ||
                                  int.parse(value) <= 0) {
                                return '>0';
                              }
                              return null;
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppTheme.critical,
                          onPressed:
                              _itemsNeeded.length > 1
                                  ? () => setState(
                                    () => _itemsNeeded.removeAt(index),
                                  )
                                  : null,
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(
                        () => _itemsNeeded.add(
                          const _ItemNeed(itemName: '', qty: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Item'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickPhoto,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _photo == null ? 'Attach Photo' : 'Photo attached',
                    ),
                  ),
                  if (_photo != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_photo!.path),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : () => _submit(inventory),
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
                            : const Text('Submit Request'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemNeed {
  final String itemName;
  final int qty;

  const _ItemNeed({required this.itemName, required this.qty});

  _ItemNeed copyWith({String? itemName, int? qty}) {
    return _ItemNeed(
      itemName: itemName ?? this.itemName,
      qty: qty ?? this.qty,
    );
  }
}
