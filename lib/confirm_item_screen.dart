// lib/confirm_item_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';

class ConfirmItemScreen extends StatefulWidget {
  final String imagePath;
  final String detectedItemName; // <-- 1. TERIMA NAMA ITEM

  const ConfirmItemScreen({
    super.key,
    required this.imagePath,
    required this.detectedItemName, // <-- 1. TERIMA NAMA ITEM
  });

  @override
  State<ConfirmItemScreen> createState() => _ConfirmItemScreenState();
}

class _ConfirmItemScreenState extends State<ConfirmItemScreen> {
  final _itemNameController = TextEditingController();
  int _quantity = 1;
  int _selectedRipeness = 2; // Default ke "Matang"
  final ripenessOptions = ['Mentah', 'Setengah Matang', 'Matang'];
  
  final FirestoreService _firestoreService = FirestoreService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 2. ISI FORM DENGAN NAMA YANG SUDAH TERDETEKSI
    _itemNameController.text = widget.detectedItemName;
  }

  Future<void> _saveItem() async {
    if (_itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama item tidak boleh kosong!')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _firestoreService.addItem(
        itemName: _itemNameController.text,
        quantity: _quantity,
        initialCondition: ripenessOptions[_selectedRipeness],
        imagePath: widget.imagePath,
      );

      if (mounted) {
        int popCount = 0;
        Navigator.popUntil(context, (route) => popCount++ >= 1); // Cukup pop 1x
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    super.dispose();
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(widget.imagePath),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
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
            ),
            const SizedBox(height: 24),
            // (Sisa UI tidak berubah)
            const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => {if (_quantity > 1) setState(() => _quantity--)}),
                Expanded(child: Text('$_quantity', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: () => setState(() => _quantity++)),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Tingkat Kematangan', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: List<Widget>.generate(3, (int index) {
                return ChoiceChip(
                  label: Text(ripenessOptions[index]),
                  selected: _selectedRipeness == index,
                  onSelected: (bool selected) => setState(() => _selectedRipeness = index),
                  selectedColor: Colors.green[100],
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
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Simpan ke Inventaris', style: TextStyle(fontSize: 16)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Ambil Ulang Gambar'),
            ),
          ],
        ),
      ),
    );
  }
}