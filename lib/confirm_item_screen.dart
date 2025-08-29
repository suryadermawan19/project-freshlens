// lib/confirm_item_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
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

  int _quantity = 1;
  int _selectedRipeness = -1; // -1 berarti belum ada yang dipilih
  final ripenessOptions = ['Mentah', 'Setengah Matang', 'Matang'];
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
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRipeness == -1) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tingkat kematangan terlebih dahulu'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await FirestoreService().addItem(
        itemName: _itemNameController.text,
        quantity: _quantity,
        initialCondition: ripenessOptions[_selectedRipeness],
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
      backgroundColor: const Color(0xFFFAF8F1),
      appBar: AppBar(
        title: const Text('Konfirmasi Item'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(File(widget.imagePath), height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
              const SizedBox(height: 24),
              const Text('Nama Item', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _itemNameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Nama item tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),
              const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.remove_circle_outline, size: 32), onPressed: () => {if (_quantity > 1) setState(() => _quantity--)}),
                  const SizedBox(width: 24),
                  Text('$_quantity', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 24),
                  IconButton(icon: const Icon(Icons.add_circle_outline, size: 32), onPressed: () => setState(() => _quantity++)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Tingkat Kematangan', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                alignment: WrapAlignment.center,
                children: List<Widget>.generate(3, (int index) {
                  return ChoiceChip(
                    label: Text(ripenessOptions[index]),
                    selected: _selectedRipeness == index,
                    onSelected: (bool selected) => setState(() => _selectedRipeness = selected ? index : -1),
                    selectedColor: const Color(0xFFC8E6C9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey[300]!)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5D8A41),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isSaving 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan ke Inventaris', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}