// lib/dashboard_screen.dart (REVISI LENGKAP FINAL)

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

// --- BAGIAN NAVIGATION BAWAH TIDAK BERUBAH ---
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
                icon: Icons.home_outlined, label: 'Beranda', index: 0),
            _buildNavItem(
                icon: FontAwesomeIcons.bookOpen,
                label: 'Edukasi',
                index: 1,
                isFaIcon: true),
            const SizedBox(width: 40),
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
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              isFaIcon
                  ? FaIcon(icon, color: color, size: 20)
                  : Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }
}

// --- BAGIAN KONTEN DASHBOARD DENGAN LOGIKA YANG DIPERBAIKI ---
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
    setState(() {
      _urgentDays = prefs.getInt('urgentDays') ?? 4;
    });
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

            // Filter item yang urgent dari hasil grouping
            final urgentItemGroups = groupedItems.where((group) {
              final shortestDays = group.batches.map((b) => b.predictedShelfLife).reduce((a, b) => a < b ? a : b);
              return shortestDays <= _urgentDays;
            }).toList();
            // Urutkan item kritis dari yang paling mendesak
            urgentItemGroups.sort((a, b) {
               final shortestDaysA = a.batches.map((batch) => batch.predictedShelfLife).reduce((val, el) => val < el ? val : el);
               final shortestDaysB = b.batches.map((batch) => batch.predictedShelfLife).reduce((val, el) => val < el ? val : el);
               return shortestDaysA.compareTo(shortestDaysB);
            });

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _firestoreService.getUserProfile(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return _buildHeader(name: 'Pengguna');
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      return _buildHeader(
                        name: userData['name'] ?? 'Pengguna',
                        imageUrl: userData['profileImageUrl'],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _firestoreService.getLatestSensorData(),
                    builder: (context, sensorSnapshot) {
                      if (!sensorSnapshot.hasData || !sensorSnapshot.data!.exists) {
                        return _buildSensorRow(temperature: '0', humidity: '0');
                      }
                      final sensorData = sensorSnapshot.data!.data() as Map<String, dynamic>;
                      final temp = sensorData['temperature']?.toStringAsFixed(1) ?? '0';
                      final humid = sensorData['humidity']?.toStringAsFixed(1) ?? '0';
                      return _buildSensorRow(temperature: temp, humidity: humid);
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('Segera Habiskan'),
                const SizedBox(height: 12),
                _buildUrgentItemsCarousel(urgentItemGroups), // Kirim hasil grouping
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Inventaris Saya', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(onPressed: widget.onViewAllTapped, child: const Text('Lihat semua')),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (groupedItems.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                    child: Center(
                      child: Text('Inventaris kosong. Tambahkan item dengan tombol kamera!',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...groupedItems.take(3).map((itemGroup) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: InventoryListItem(
                        itemName: itemGroup.itemName,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ItemDetailScreen(itemGroup: itemGroup)));
                        },
                      ),
                    );
                  }),
                const SizedBox(height: 40),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader({required String name, String? imageUrl}) {
    final displayName = name.split(' ').first;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null ? Text(name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 28)) : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, $displayName!', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, height: 1.2)),
            const SizedBox(height: 4),
            Text('Selamat datang kembali', style: TextStyle(color: Colors.grey[700])),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSensorRow({required String temperature, required String humidity}) {
    final double tempValue = double.tryParse(temperature) ?? 0.0;
    final double humidValue = double.tryParse(humidity) ?? 0.0;
    return Row(
      children: [
        Expanded(
          child: SensorCard(
            title: 'Suhu',
            icon: Icons.thermostat,
            value: temperature,
            unit: '°C',
            color: Colors.blue.shade700,
            sensorValue: tempValue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SensorCard(
            title: 'Kelembapan',
            icon: Icons.water_drop_outlined,
            value: humidity,
            unit: '%',
            color: Colors.green.shade700,
            sensorValue: humidValue,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildUrgentItemsCarousel(List<InventoryItemGroup> items) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        height: 100,
        child: const Center(
          child: Text('Tidak ada item yang perlu segera diolah. Bagus!',
              style: TextStyle(color: Colors.grey)),
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
          final shortestDays = itemGroup.batches.map((b) => b.predictedShelfLife).reduce((a, b) => a < b ? a : b);
          return Padding(
            padding: EdgeInsets.only(right: index == items.length - 1 ? 0 : 12),
            child: GestureDetector( // Dibungkus GestureDetector agar bisa di-tap
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(itemGroup: itemGroup),
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
  
  List<InventoryItemGroup> _groupItems(List<DocumentSnapshot> allItems) {
    final Map<String, List<DocumentSnapshot>> groupedItems = {};
    for (var doc in allItems) {
      final data = doc.data() as Map<String, dynamic>;
      final itemName = data['itemName'] as String;
      if (groupedItems[itemName] == null) groupedItems[itemName] = [];
      groupedItems[itemName]!.add(doc);
    }
    return groupedItems.entries.map((entry) {
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
          predictedShelfLife: data['predictedShelfLife'] ?? 7,
          initialCondition: data['initialCondition'] ?? 'Tidak diketahui',
        );
      }).toList();
      return InventoryItemGroup(itemName: itemName, imagePath: imagePath, batches: batches);
    }).toList();
  }
}