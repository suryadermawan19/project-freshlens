// lib/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:freshlens_ai_app/models/inventory_item_model.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'item_detail_screen.dart';
import 'sensor_card.dart';
import 'urgent_item_card.dart';
import 'inventory_list_item.dart';
import 'education_screen.dart';
import 'inventory_screen.dart';
import 'profile_screen.dart';
import 'camera_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = <Widget>[
      DashboardContent(onViewAllTapped: () => _onItemTapped(2)),
      const EducationScreen(),
      const InventoryScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: pages),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const CameraScreen())),
        backgroundColor: const Color(0xFF5D8A41),
        foregroundColor: Colors.white,
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt_outlined, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildNavItem(
                icon: Icons.home_filled, label: 'Beranda', index: 0),
            _buildNavItem(
                icon: FontAwesomeIcons.book,
                label: 'Edukasi',
                index: 1,
                isFaIcon: true),
            const SizedBox(width: 48),
            _buildNavItem(
                icon: Icons.inventory_2_outlined,
                label: 'Inventaris',
                index: 2),
            _buildNavItem(
                icon: Icons.person_outline, label: 'Profil', index: 3),
          ],
        ),
      ),
    );
  }

  // ### KODE YANG DIPERBAIKI ADA DI BAWAH INI ###
  Widget _buildNavItem(
      {required IconData icon,
      required String label,
      required int index,
      bool isFaIcon = false}) {
    final bool isSelected = _selectedIndex == index;
    final Color color = isSelected ? const Color(0xFF5D8A41) : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0), // Padding disesuaikan
          child: Column(
            mainAxisSize: MainAxisSize.min, // Perbaikan utama untuk overflow
            children: <Widget>[
              isFaIcon
                  ? FaIcon(icon, color: color, size: 20)
                  : Icon(icon, color: color, size: 24),
              const SizedBox(height: 2), // Jarak disesuaikan
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

// ### TIDAK ADA PERUBAHAN PADA KODE DI BAWAH INI ###

class DashboardContent extends StatefulWidget {
  final VoidCallback onViewAllTapped;
  const DashboardContent({super.key, required this.onViewAllTapped});
  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getInventoryItems(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final allDocs = snapshot.data?.docs ?? [];
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
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSensorSection(),
                const SizedBox(height: 24),
                _buildSectionTitle('Segera Habiskan'),
                const SizedBox(height: 12),
                _buildUrgentItemsCarousel(urgentItemGroups),
                const SizedBox(height: 24),
                _buildInventoryPreviewSection(groupedItems),
                const SizedBox(height: 80),
              ],
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserProfile(),
        builder: (context, userSnapshot) {
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
                child: imageUrl == null
                    ? Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
                        style: const TextStyle(fontSize: 28, color: Colors.black54),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Halo, $displayName!',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          height: 1.2)),
                  const SizedBox(height: 4),
                  Text('Selamat datang kembali',
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_outlined),
                iconSize: 28,
                color: Colors.grey[800],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSensorSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: SizedBox(
        height: 170,
        child: StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getLatestSensorData(),
          builder: (context, sensorSnapshot) {
            final temp = (sensorSnapshot.hasData && sensorSnapshot.data!.exists)
                ? (sensorSnapshot.data!.data() as Map<String, dynamic>)['temperature']?.toStringAsFixed(1) ?? 'N/A'
                : 'N/A';
            final humid = (sensorSnapshot.hasData && sensorSnapshot.data!.exists)
                ? (sensorSnapshot.data!.data() as Map<String, dynamic>)['humidity']?.toStringAsFixed(1) ?? 'N/A'
                : 'N/A';
            
            final tempValue = double.tryParse(temp) ?? 0.0;
            final humidValue = double.tryParse(humid) ?? 0.0;
            
            return Row(
              children: [
                Expanded(
                  child: SensorCard(
                    title: 'Suhu',
                    icon: Icons.thermostat,
                    value: temp,
                    unit: '°C',
                    color: Colors.orange.shade700,
                    sensorValue: tempValue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SensorCard(
                    title: 'Kelembapan',
                    icon: Icons.water_drop_outlined,
                    value: humid,
                    unit: '%',
                    color: Colors.blue.shade700,
                    sensorValue: humidValue,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child:
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildUrgentItemsCarousel(List<InventoryItemGroup> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        height: 100,
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green[700]),
              const SizedBox(width: 8),
              const Text('Tidak ada item yang perlu segera diolah. Bagus!',
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        itemBuilder: (context, index) {
          final itemGroup = items[index];
          final shortestDays = itemGroup.batches
              .map((b) => b.predictedShelfLife)
              .reduce((a, b) => a < b ? a : b);
          return Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 12),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ItemDetailScreen(itemGroup: itemGroup),
                    ));
              },
              child: UrgentItemCard(
                itemName: itemGroup.itemName,
                daysLeft: shortestDays,
                imageUrl: itemGroup.imagePath,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInventoryPreviewSection(List<InventoryItemGroup> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Inventaris Saya',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TextButton(
                  onPressed: widget.onViewAllTapped,
                  child: const Text('Lihat semua')),
            ],
          ),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(
                child: Text('Inventaris kosong. Tambahkan item baru!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length > 3 ? 3 : items.length,
              itemBuilder: (context, index) {
                final itemGroup = items[index];
                return InventoryListItem(
                  itemName: itemGroup.itemName,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ItemDetailScreen(itemGroup: itemGroup)));
                  },
                );
              },
            ),
        ],
      ),
    );
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
        imagePath: firstItemData['imageUrl'] ?? 'assets/images/placeholder.png',
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
}