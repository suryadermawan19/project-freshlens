// lib/confirm_item_screen.dart (Versi Terhubung ke Firebase)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart'; // <-- 1. IMPORT SERVICE KITA

class ConfirmItemScreen extends StatefulWidget {
  final String imagePath;

  const ConfirmItemScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<ConfirmItemScreen> createState() => _ConfirmItemScreenState();
}

class _ConfirmItemScreenState extends State<ConfirmItemScreen> {
  // --- STATE UNTUK FORM ---
  final _itemNameController = TextEditingController(text: 'Tomat (Contoh)'); // Controller untuk nama item
  int _quantity = 1;
  int _selectedRipeness = 0;
  final ripenessOptions = ['Mentah', 'Setengah Matang', 'Matang'];
  
  // --- STATE UNTUK LOGIKA PENYIMPANAN ---
  final FirestoreService _firestoreService = FirestoreService(); // <-- 2. BUAT INSTANCE SERVICE
  bool _isSaving = false; // Untuk mengontrol loading indicator

  // --- FUNGSI UNTUK MENYIMPAN DATA ---
  Future<void> _saveItem() async {
    // Validasi sederhana
    if (_itemNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama item tidak boleh kosong!'), backgroundColor: Colors.orange));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // <-- 3. PANGGIL FUNGSI DARI SERVICE
      await _firestoreService.addItem(
        itemName: _itemNameController.text,
        quantity: _quantity,
        initialCondition: ripenessOptions[_selectedRipeness],
        imagePath: widget.imagePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item berhasil disimpan!'), backgroundColor: Colors.green));
        // Kembali ke dua layar sebelumnya (lewat kamera dan kembali ke dasbor/inventaris)
        int popCount = 0;
        Navigator.popUntil(context, (route) => popCount++ == 2);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: Colors.red));
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
              controller: _itemNameController, // Gunakan controller
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
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
                  onSelected: (bool selected) => setState(() => _selectedRipeness = selected ? index : -1),
                  selectedColor: Colors.green[100],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.grey[300]!)),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              // <-- 4. SAMBUNGKAN FUNGSI KE TOMBOL
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}