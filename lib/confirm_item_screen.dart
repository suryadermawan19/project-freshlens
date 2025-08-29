// lib/confirm_item_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
// Import yang tidak perlu sudah dihapus
import 'package:freshlens_ai_app/service/firestore_service.dart';

class ConfirmItemScreen extends StatefulWidget {
  final String imagePath;
  final String? detectedItemName;

  const ConfirmItemScreen({
    super.key,
    required this.imagePath,
    this.detectedItemName,
  });

  @override
  State<ConfirmItemScreen> createState() => _ConfirmItemScreenState();
}

class _ConfirmItemScreenState extends State<ConfirmItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemNameController = TextEditingController();
  
  String? _selectedCondition;
  int _itemQuantity = 1;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.detectedItemName != null &&
        widget.detectedItemName!.isNotEmpty &&
        !widget.detectedItemName!.contains('...')) {
      _itemNameController.text = widget.detectedItemName!;
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await FirestoreService().addItem(
        itemName: _itemNameController.text,
        quantity: _itemQuantity,
        initialCondition: _selectedCondition!,
        imagePath: widget.imagePath,
      );
      
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Item berhasil disimpan!'), backgroundColor: Colors.green),
      );
      navigator.popUntil((route) => route.isFirst);

    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Item'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.file(File(widget.imagePath), height: 250, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _itemNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Item',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_basket_outlined),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Nama item tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Kondisi Awal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.grain_outlined),
                ),
                items: <String>['Segar', 'Mentah', 'Setengah Matang', 'Matang']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedCondition = newValue);
                },
                validator: (value) => value == null ? 'Pilih kondisi awal item' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 32),
                    onPressed: () {
                      if (_itemQuantity > 1) setState(() => _itemQuantity--);
                    },
                  ),
                  const SizedBox(width: 24),
                  Text('$_itemQuantity', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 32),
                    onPressed: () => setState(() => _itemQuantity++),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveItem,
                icon: _isSaving ? Container() : const Icon(Icons.save),
                label: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan Item'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}