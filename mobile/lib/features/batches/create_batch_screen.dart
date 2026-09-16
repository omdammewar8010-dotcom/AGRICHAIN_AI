import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../models/crop_batch_model.dart';
import '../../providers/providers.dart';

class CreateBatchScreen extends ConsumerStatefulWidget {
  const CreateBatchScreen({super.key});

  @override
  ConsumerState<CreateBatchScreen> createState() => _CreateBatchScreenState();
}

class _CreateBatchScreenState extends ConsumerState<CreateBatchScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedCrop = 'Tomato';
  final _quantityController = TextEditingController(text: '1500');
  final _shelfLifeController = TextEditingController(text: '96');
  final _tempMinController = TextEditingController(text: '18.0');
  final _tempMaxController = TextEditingController(text: '22.0');
  final _humMinController = TextEditingController(text: '60.0');
  final _humMaxController = TextEditingController(text: '75.0');
  String _selectedGrade = 'A';
  bool _isSubmitting = false;

  void _onCropChanged(String? crop) {
    if (crop == null) return;
    setState(() {
      _selectedCrop = crop;
      if (crop == 'Tomato') {
        _tempMinController.text = '18.0';
        _tempMaxController.text = '22.0';
        _shelfLifeController.text = '96';
      } else if (crop == 'Grapes') {
        _tempMinController.text = '0.0';
        _tempMaxController.text = '2.0';
        _shelfLifeController.text = '120';
      } else if (crop == 'Pomegranate') {
        _tempMinController.text = '5.0';
        _tempMaxController.text = '8.0';
        _shelfLifeController.text = '360';
      } else if (crop == 'Milk') {
        _tempMinController.text = '2.0';
        _tempMaxController.text = '4.0';
        _shelfLifeController.text = '48';
      } else if (crop == 'Banana') {
        _tempMinController.text = '13.0';
        _tempMaxController.text = '15.0';
        _shelfLifeController.text = '168';
      }
    });
  }

  Future<void> _submitBatch() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final randomId = 'AGRI-2026-${_selectedCrop.substring(0, 3).toUpperCase()}-${Random().nextInt(900000) + 100000}';
    final user = ref.read(currentUserProvider);

    final batch = CropBatchModel(
      batchId: randomId,
      cropName: _selectedCrop,
      cropCategory: _selectedCrop == 'Grapes' || _selectedCrop == 'Banana' || _selectedCrop == 'Pomegranate' ? 'Fruit' : 'Vegetable',
      quantity: double.tryParse(_quantityController.text) ?? 1000.0,
      unit: _selectedCrop == 'Milk' ? 'Liters' : 'kg',
      farmerId: user.userId,
      farmId: user.farmId ?? 'FARM-NASHIK-01',
      harvestDate: DateTime.now().toIso8601String().split('T').first,
      expectedShelfLifeHours: double.tryParse(_shelfLifeController.text) ?? 96.0,
      preferredTempMin: double.tryParse(_tempMinController.text) ?? 18.0,
      preferredTempMax: double.tryParse(_tempMaxController.text) ?? 22.0,
      preferredHumMin: double.tryParse(_humMinController.text) ?? 60.0,
      preferredHumMax: double.tryParse(_humMaxController.text) ?? 75.0,
      qualityGrade: _selectedGrade,
      currentStatus: 'registered',
      originAddress: 'Sahyadri Agro Farms, Nashik',
      originLat: 19.9975,
      originLng: 73.7898,
      destinationAddress: 'APMC Market Vashi, Mumbai',
      destLat: 19.0760,
      destLng: 72.8777,
    );

    await ref.read(batchRepoProvider).createBatch(batch);
    setState(() => _isSubmitting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Batch $randomId registered successfully! Generating QR...'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
      context.push('/qr/$randomId');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Crop Harvest')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'HARVEST SPECIFICATIONS',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),

              // Crop Variety Selector
              DropdownButtonFormField<String>(
                value: _selectedCrop,
                decoration: const InputDecoration(labelText: 'Crop Commodity'),
                items: AppConstants.supportedCrops.map((crop) {
                  return DropdownMenuItem(value: crop, child: Text(crop));
                }).toList(),
                onChanged: _onCropChanged,
              ),
              const SizedBox(height: 16),

              // Quantity & Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity Harvested'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedGrade,
                      decoration: const InputDecoration(labelText: 'Grade'),
                      items: const [
                        DropdownMenuItem(value: 'A+', child: Text('Grade A+')),
                        DropdownMenuItem(value: 'A', child: Text('Grade A')),
                        DropdownMenuItem(value: 'B', child: Text('Grade B')),
                      ],
                      onChanged: (v) => setState(() => _selectedGrade = v ?? 'A'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Shelf Life
              TextFormField(
                controller: _shelfLifeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Expected Shelf-Life (Hours)',
                  suffixText: 'hours',
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'COLD CHAIN STORAGE CONSTRAINTS',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              const SizedBox(height: 12),

              // Safe Temperature Range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _tempMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min Temp (°C)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _tempMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Temp (°C)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Safe Humidity Range
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _humMinController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Min Humidity (%)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _humMaxController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Max Humidity (%)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitBatch,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Register Batch & Generate QR Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
