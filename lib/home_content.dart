// lib/home_content.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/inventory_screen.dart';
import 'package:freshlens_ai_app/item_detail_screen.dart';
import 'package:freshlens_ai_app/models/inventory_item_model.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:freshlens_ai_app/widgets/inventory_preview_card.dart';
import 'package:freshlens_ai_app/sensor_card.dart';
import 'package:freshlens_ai_app/widgets/shimmer_box.dart';
import 'package:freshlens_ai_app/urgent_item_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class HomeContent extends StatefulWidget {
  final VoidCallback onViewAllTapped;

  const HomeContent({super.key, required this.onViewAllTapped});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final FirestoreService _firestoreService = FirestoreService();
  int _urgentDays = 4;

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  Future<void> _loadThresholds() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _urgentDays = prefs.getInt('urgentDays') ?? 4;
      });
    }
  }

  List<InventoryItemGroup> _groupItems(List<DocumentSnapshot> allItems) {
    final Map<String, List<DocumentSnapshot>> groupedData = {};
    for (var doc in allItems) {
      final data = doc.data() as Map<String, dynamic>;
      final itemName = data['itemName'] as String;
      if (groupedData[itemName] == null) groupedData[itemName] = [];
      groupedData[itemName]!.add(doc);
    }
    return groupedData.entries.map((entry) {
      final batchesData = entry.value;
      final firstItemData = batchesData.first.data() as Map<String, dynamic>;
      return InventoryItemGroup(
        itemName: entry.key,
        imagePath: firstItemData['imageUrl'] ?? '',
        batches: batchesData.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Batch(
            id: doc.id,
            entryDate: (data['entryDate'] as Timestamp? ?? Timestamp.now()).toDate(),
            quantity: data['quantity'] ?? 0,
            predictedShelfLife: data['predictedShelfLife'] ?? 7,
            initialCondition: data['initialCondition'] ?? 'Tidak diketahui',
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getInventoryItems(),
      builder: (context, inventorySnapshot) {
        if (inventorySnapshot.connectionState == ConnectionState.waiting || !inventorySnapshot.hasData) {
          return _buildShimmerLoadingState();
        }

        final allDocs = inventorySnapshot.data?.docs ?? [];
        final groupedItems = _groupItems(allDocs);

        final urgentItemGroups = groupedItems.where((group) {
          final shortestDays = group.batches.map((b) => b.predictedShelfLife).reduce((a, b) => a < b ? a : b);
          return shortestDays <= _urgentDays;
        }).toList();
        urgentItemGroups.sort((a, b) {
           final shortestDaysA = a.batches.map((batch) => batch.predictedShelfLife).reduce((val, el) => val < el ? val : el);
           final shortestDaysB = b.batches.map((batch) => batch.predictedShelfLife).reduce((val, el) => val < el ? val : el);
           return shortestDaysA.compareTo(shortestDaysB);
        });

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildSensorSection(context),
            const SizedBox(height: 32),
            _buildSectionTitle(context, title: 'Segera Habiskan'),
            const SizedBox(height: 16),
            _buildUrgentItemsCarousel(context, urgentItemGroups),
            const SizedBox(height: 32),
            _buildSectionTitle(context, title: 'Inventaris Saya', showViewAll: true),
            _buildInventoryPreview(context, groupedItems),
          ],
        );
      },
    );
  }

  Widget _buildShimmerLoadingState() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                ShimmerBox(width: 56, height: 56, shapeBorder: CircleBorder()),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 150, height: 20),
                    SizedBox(height: 8),
                    ShimmerBox(width: 120, height: 14),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Expanded(child: ShimmerBox(width: double.infinity, height: 130, shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))))),
                SizedBox(width: 16),
                Expanded(child: ShimmerBox(width: double.infinity, height: 130, shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))))),
              ],
            ),
          ),
          const SizedBox(height: 32),
           const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: ShimmerBox(width: 200, height: 24),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemBuilder: (context, index) => const Padding(
                padding: EdgeInsets.only(right: 16.0),
                child: ShimmerBox(width: 150, height: 220, shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))))
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserProfile(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) {
            return const Row(
              children: [
                ShimmerBox(width: 56, height: 56, shapeBorder: CircleBorder()),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 150, height: 20),
                    SizedBox(height: 8),
                    ShimmerBox(width: 120, height: 14),
                  ],
                ),
              ],
            );
          }

          final name = (userSnapshot.hasData && userSnapshot.data!.exists)
              ? (userSnapshot.data!.data() as Map<String, dynamic>)['name'] as String? ?? 'Pengguna'
              : 'Pengguna';
          final imageUrl = (userSnapshot.hasData && userSnapshot.data!.exists)
              ? (userSnapshot.data!.data() as Map<String, dynamic>)['profileImageUrl'] as String?
              : null;
          
          final displayName = name.split(' ').first;

          return Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null ? Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A') : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, $displayName!', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Selamat datang kembali', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                ],
              ),
              const Spacer(),
              IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_outlined, size: 28), color: Colors.grey[800]),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSensorSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getLatestSensorData(),
        builder: (context, sensorSnapshot) {
          if (!sensorSnapshot.hasData) {
            return const Row(
              children: [
                Expanded(child: ShimmerBox(width: double.infinity, height: 130, shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))))),
                SizedBox(width: 16),
                Expanded(child: ShimmerBox(width: double.infinity, height: 130, shapeBorder: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))))),
              ],
            );
          }
          final temp = (sensorSnapshot.hasData && sensorSnapshot.data!.exists)
              ? (sensorSnapshot.data!.data() as Map<String, dynamic>)['temperature']?.toStringAsFixed(1) ?? 'N/A'
              : 'N/A';
          final humid = (sensorSnapshot.hasData && sensorSnapshot.data!.exists)
              ? (sensorSnapshot.data!.data() as Map<String, dynamic>)['humidity']?.toStringAsFixed(1) ?? 'N/A'
              : 'N/A';
          
          return SizedBox(
            height: 130,
            child: Row(
              children: [
                Expanded(child: SensorCard(title: 'Suhu', value: temp, unit: '°C', icon: Icons.thermostat, color: Colors.orange.shade700)),
                const SizedBox(width: 16),
                Expanded(child: SensorCard(title: 'Kelembapan', value: humid, unit: '%', icon: Icons.water_drop_outlined, color: Colors.blue.shade700)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, {required String title, bool showViewAll = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          if (showViewAll)
            TextButton(
              onPressed: widget.onViewAllTapped,
              child: const Text('Lihat semua'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildUrgentItemsCarousel(BuildContext context, List<InventoryItemGroup> items) {
  if (items.isEmpty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      height: 100,
      child: Center(child: Text('Tidak ada item yang perlu segera diolah.', style: TextStyle(color: Colors.grey[600]))),
    );
  }

  return SizedBox(
    height: 220,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemBuilder: (context, index) {
        final itemGroup = items[index];
        final shortestDays = itemGroup.batches.map((b) => b.predictedShelfLife).reduce((a, b) => a < b ? a : b);
        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          // [DIUBAH] Bungkus dengan GestureDetector
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(itemGroup: itemGroup),
                ),
              );
            },
            child: UrgentItemCard(
              imageUrl: itemGroup.imagePath,
              itemName: itemGroup.itemName,
              daysLeft: shortestDays,
            ),
          ),
        );
      },
    ),
  );
}

  Widget _buildInventoryPreview(BuildContext context, List<InventoryItemGroup> items) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(child: Text('Inventaris Anda kosong.', style: TextStyle(color: Colors.grey[600]))),
      );
    }
    
    final previewItems = items.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: previewItems.length,
        itemBuilder: (context, index) {
          final itemGroup = previewItems[index];
          return InventoryPreviewCard(
            itemGroup: itemGroup,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(itemGroup: itemGroup),
                ),
              );
            },
          );
        },
      ),
    );
  }
}