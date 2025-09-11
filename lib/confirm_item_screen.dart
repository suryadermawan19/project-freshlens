// lib/confirm_item_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:freshlens_ai_app/providers/loading_provider.dart';

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
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  int _quantity = 1;
  String? _selectedCondition;
  final List<String> _conditions = ['Mentah', 'Setengah Matang', 'Segar', 'Matang',];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.detectedItemName);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    // Validasi form
    if (!_formKey.currentState!.validate()) {
      return;
    }
    // Pastikan kondisi sudah dipilih
    if (_selectedCondition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kondisi awal item.'), backgroundColor: Colors.orange),
      );
      return;
    }

    final loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    loadingProvider.startLoading();

    try {
      final firestoreService = FirestoreService();
      await firestoreService.addItem(
        itemName: _nameController.text.trim(),
        quantity: _quantity,
        initialCondition: _selectedCondition!,
        imagePath: widget.imagePath,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item berhasil ditambahkan!'), backgroundColor: Colors.green),
        );
        // Kembali ke halaman utama setelah berhasil
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan item: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      loadingProvider.stopLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Item'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pratinjau Gambar
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(widget.imagePath),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // Form Nama Item
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Item',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama item tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Form Jumlah
              _buildQuantitySelector(),
              const SizedBox(height: 20),

              // Form Kondisi Awal
              DropdownButtonFormField<String>(
                value: _selectedCondition,
                decoration: const InputDecoration(
                  labelText: 'Kondisi Awal',
                  prefixIcon: Icon(Icons.thermostat_auto_outlined),
                ),
                items: _conditions.map((String condition) {
                  return DropdownMenuItem<String>(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCondition = newValue;
                  });
                },
                validator: (value) => value == null ? 'Pilih kondisi' : null,
              ),
              const SizedBox(height: 40),

              // Tombol Simpan
              Consumer<LoadingProvider>(
                builder: (context, loadingProvider, child) {
                  return loadingProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveItem,
                          child: const Text('SIMPAN KE INVENTARIS'),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget helper untuk pemilih jumlah
  Widget _buildQuantitySelector() {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Jumlah',
        prefixIcon: Icon(Icons.format_list_numbered),
        border: InputBorder.none, // Hapus border bawaan agar terlihat rapi
        enabledBorder: InputBorder.none,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () {
              if (_quantity > 1) {
                setState(() => _quantity--);
              }
            },
          ),
          Text('$_quantity', style: Theme.of(context).textTheme.headlineMedium),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              setState(() => _quantity++);
            },
          ),
        ],
      ),
    );
  }
}