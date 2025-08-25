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

class DashboardContent extends StatefulWidget {
  final VoidCallback onViewAllTapped;
  const DashboardContent({super.key, required this.onViewAllTapped});
  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final TextEditingController _searchController = TextEditingController();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<DocumentSnapshot>(
                stream: _firestoreService.getUserProfile(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _buildHeader(name: 'Pengguna', imageUrl: null);
                  }
                  final userData = snapshot.data!.data() as Map<String, dynamic>;
                  return _buildHeader(
                    name: userData['name'] ?? 'Pengguna',
                    imageUrl: userData['profileImageUrl'],
                  );
                },
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Telusuri inventaris Anda...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none),
                ),
                onChanged: (query) => setState(() {}),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getInventoryItems(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyDashboardContent();
                  }

                  final allItems = snapshot.data!.docs;

                  if (_searchController.text.isNotEmpty) {
                    final searchResult = allItems.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return (data['itemName'] as String)
                          .toLowerCase()
                          .contains(_searchController.text.toLowerCase());
                    }).toList();
                    return _buildSearchResults(searchResult);
                  }
                  return _buildDashboardContent(allItems);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({required String name, required String? imageUrl}) {
    final displayName = name.split(' ').first;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null
              ? Text(
                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
                  style: const TextStyle(fontSize: 28),
                )
              : null,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo,\n$displayName!',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.2)),
            const SizedBox(height: 4),
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
                children: <TextSpan>[
                  TextSpan(text: 'Selamat Datang di '),
                  TextSpan(
                      text: 'FreshLens AI',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<DocumentSnapshot> results) {
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(child: Text('Item tidak ditemukan.')),
      );
    }
    // ... implementasi UI hasil pencarian
    return Container();
  }

  Widget _buildDashboardContent(List<DocumentSnapshot> allItems) {
    final urgentItems = allItems.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return (data['predictedShelfLife'] ?? 10) <= _urgentDays;
    }).toList();

    final itemGroups = _groupItems(allItems);
    final previewItemGroups = itemGroups.take(3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Row(children: [
          Icon(Icons.wb_sunny_outlined),
          SizedBox(width: 8),
          Text('Segera Habiskan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        if (urgentItems.isEmpty)
          const Text('Tidak ada item yang perlu segera diolah. Bagus!')
        else
          ...urgentItems.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: UrgentItemCard(
                itemIcon: FontAwesomeIcons.carrot,
                itemName: data['itemName'],
                daysLeft: 'Sisa ${data['predictedShelfLife'] ?? '?'} hari',
              ),
            );
          }),
        const SizedBox(height: 30),
        // --- PERUBAHAN UTAMA DI SINI ---
        StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getLatestSensorData(),
          builder: (context, snapshot) {
            // Tampilkan data default jika tidak ada data sensor
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return _buildSensorRow(temperature: '--', humidity: '--');
            }
            final sensorData = snapshot.data!.data() as Map<String, dynamic>;
            final temp = sensorData['temperature']?.toStringAsFixed(1) ?? '--';
            final humid = sensorData['humidity']?.toStringAsFixed(1) ?? '--';
            return _buildSensorRow(temperature: temp, humidity: humid);
          },
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined),
            const SizedBox(width: 8),
            const Text('Inventaris', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
                onPressed: widget.onViewAllTapped,
                child: const Text('Lihat semua')),
          ],
        ),
        const SizedBox(height: 8),
        ...previewItemGroups.map((itemGroup) {
          return InventoryListItem(
            itemName: itemGroup.itemName,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(itemGroup: itemGroup),
                ),
              );
            },
          );
        }),
      ],
    );
  }
  
  // --- WIDGET BARU UNTUK BARIS SENSOR ---
  Widget _buildSensorRow({required String temperature, required String humidity}) {
    return Row(
      children: [
        Expanded(
          child: SensorCard(
            title: 'Suhu',
            icon: Icons.thermostat,
            value: temperature,
            unit: '° C',
            status: 'Normal', // Status bisa dibuat dinamis nanti
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SensorCard(
            title: 'Kelembapan',
            icon: Icons.water_drop_outlined,
            value: humidity,
            unit: '%',
            status: 'Optimal', // Status bisa dibuat dinamis nanti
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyDashboardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Row(children: [
          Icon(Icons.wb_sunny_outlined),
          SizedBox(width: 8),
          Text('Segera Habiskan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 16),
        const Text("Semua bahan makanan Anda masih segar!"),
        const SizedBox(height: 30),
        // Tampilkan sensor dengan data default
        _buildSensorRow(temperature: '--', humidity: '--'),
        const SizedBox(height: 30),
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined),
            const SizedBox(width: 8),
            const Text('Inventaris', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
                onPressed: widget.onViewAllTapped,
                child: const Text('Lihat semua')),
          ],
        ),
        const SizedBox(height: 16),
        const Text("Inventaris Anda masih kosong."),
      ],
    );
  }

  List<InventoryItemGroup> _groupItems(List<DocumentSnapshot> allItems) {
    final Map<String, List<DocumentSnapshot>> groupedItems = {};
    for (var doc in allItems) {
      final data = doc.data() as Map<String, dynamic>;
      final itemName = data['itemName'] as String;
      if (groupedItems[itemName] == null) {
        groupedItems[itemName] = [];
      }
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
      return InventoryItemGroup(
        itemName: itemName,
        imagePath: imagePath,
        batches: batches,
      );
    }).toList();
  }
}