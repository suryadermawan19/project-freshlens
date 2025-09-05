// lib/confirm_item_screen.dart (REVISI: autofill dari Cloud Vision + simpan ke Firestore)
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:freshlens_ai_app/dashboard_screen.dart';

class ConfirmItemScreen extends StatefulWidget {
  final String imagePath;
  final String detectedItemName;

  const ConfirmItemScreen({
    super.key,
    required this.imagePath,
    required this.detectedItemName,
  });

  @override
  State<ConfirmItemScreen> createState() => _ConfirmItemScreenState();
}

class _ConfirmItemScreenState extends State<ConfirmItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late final TextEditingController _nameController;
  final TextEditingController _qtyController = TextEditingController(text: '1');

  // opsi kondisi awal — sesuaikan dengan yang dipakai di training kolom & backend
  final List<String> _initialConditions = const [
    'Matang',
    'Mentah',
    'Segar',
    'Setengah Matang',
  ];

  String _selectedCondition = 'Segar';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: _normalizeLabel(widget.detectedItemName),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  // Normalisasi label Cloud Vision → nama item yang konsisten (Indonesia)
  String _normalizeLabel(String raw) {
    final l = raw.trim().toLowerCase();

    // mapping umum EN → ID (tambah sendiri bila perlu)
    const Map<String, String> mapEnToId = {
      'apple': 'Apel',
      'banana': 'Pisang',
      'mango': 'Mangga',
      'orange': 'Jeruk',
      'grape': 'Anggur',
      'grapes': 'Anggur',
      'strawberry': 'Stroberi',
      'tomato': 'Tomat',
      'avocado': 'Alpukat',
      'pineapple': 'Nanas',
      'pear': 'Pir',
      'watermelon': 'Semangka',
      'papaya': 'Pepaya',
      'kiwi': 'Kiwi',
      'lemon': 'Lemon',
      'lime': 'Jeruk Nipis',
    };

    // kalau label sudah Indonesia, biarkan
    const Set<String> knownId = {
      'apel', 'pisang', 'mangga', 'jeruk', 'anggur', 'stroberi',
      'tomat', 'alpukat', 'nanas', 'pir', 'semangka', 'pepaya',
      'kiwi', 'lemon', 'jeruk nipis',
    };

    if (mapEnToId.containsKey(l)) return mapEnToId[l]!;
    if (knownId.contains(l)) {
      // kapitalisasi huruf awal tiap kata
      return l.split(' ').map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }

    // fallback: kapitalisasi label asli
    if (raw.isEmpty) return 'Tidak terdeteksi';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final name = _nameController.text.trim();
    final qtyStr = _qtyController.text.trim();
    final qty = int.tryParse(qtyStr) ?? 0;

    if (qty <= 0) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _firestoreService.addItem(
        itemName: name,
        quantity: qty,
        initialCondition: _selectedCondition,
        imagePath: widget.imagePath, // FirestoreService akan upload ke Storage
      );

      // kembali ke dashboard
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal menyimpan item: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.imagePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Preview foto
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                imageFile,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),

            // Form konfirmasi
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Nama item
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Item',
                      prefixIcon: Icon(Icons.local_grocery_store_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 12),

                  // Jumlah
                  TextFormField(
                    controller: _qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      prefixIcon: Icon(Icons.tag_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Masukkan jumlah yang valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Kondisi awal
                  DropdownButtonFormField<String>(
                    value: _selectedCondition,
                    items: _initialConditions
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCondition = v ?? _selectedCondition),
                    decoration: const InputDecoration(
                      labelText: 'Kondisi Awal',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tombol simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _saveItem,
                      icon: _saving
                          ? const SizedBox(
                              width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline),
                      label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF5D8A41),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
