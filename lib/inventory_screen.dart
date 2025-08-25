// lib/inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'models/inventory_item_model.dart';
import 'item_detail_screen.dart';
import 'inventory_group_item.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Helper function untuk menentukan status berdasarkan sisa hari
  String _getStatusForDays(int days) {
    if (days <= 2) return 'Kritis';
    if (days <= 4) return 'Segera Olah';
    return 'Segar';
  }
  
  // Helper function untuk mendapatkan nilai prioritas dari status
  int _getPriorityForStatus(String status) {
    switch (status) {
      case 'Kritis':
        return 1;
      case 'Segera Olah':
        return 2;
      case 'Segar':
        return 3;
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      appBar: AppBar(
        title: const Text('Inventaris'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFAF8F1),
        foregroundColor: Colors.black,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getInventoryItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Inventaris Anda kosong.\n\nTekan tombol kamera di bawah untuk menambahkan item pertama Anda!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            );
          }

          final itemDocs = snapshot.data!.docs;

          // Mengelompokkan item berdasarkan nama
          final Map<String, List<DocumentSnapshot>> groupedItems = {};
          for (var doc in itemDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final itemName = data['itemName'] as String;
            if (groupedItems[itemName] == null) {
              groupedItems[itemName] = [];
            }
            groupedItems[itemName]!.add(doc);
          }

          // Ubah map menjadi list dari InventoryItemGroup
          final List<InventoryItemGroup> allItemGroups = groupedItems.entries.map((entry) {
            final itemName = entry.key;
            final batchesData = entry.value;
            final firstItemData = batchesData.first.data() as Map<String, dynamic>;
            final imagePath = firstItemData['imageUrl'] ?? 'assets/images/placeholder.png';

            final batches = batchesData.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Batch(
                id: doc.id,
                entryDate: (data['entryDate'] as Timestamp? ?? Timestamp.now()).toDate(),
                quantity: data['quantity'] ?? 0,
                predictedShelfLife: data['predictedShelfLife'] ?? 7, // Ambil dari data, fallback ke 7
              );
            }).toList();

            return InventoryItemGroup(
              itemName: itemName,
              imagePath: imagePath,
              batches: batches,
            );
          }).toList();

          // Lakukan sorting berdasarkan prioritas
          allItemGroups.sort((a, b) {
            final shortestDaysA = a.batches.map((batch) => batch.predictedShelfLife).reduce((val, el) => val < el ? val : el);
            final shortestDaysB = b.batches.map((batch) => batch.predictedShelfLife).reduce((val, el) => val < el ? val : el);
            final priorityA = _getPriorityForStatus(_getStatusForDays(shortestDaysA));
            final priorityB = _getPriorityForStatus(_getStatusForDays(shortestDaysB));
            return priorityA.compareTo(priorityB);
          });

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: allItemGroups.length,
            itemBuilder: (context, index) {
              final itemGroup = allItemGroups[index];
              return InventoryGroupItem(
                itemGroup: itemGroup,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(itemGroup: itemGroup),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const Divider(indent: 20, endIndent: 20),
          );
        },
      ),
    );
  }
}