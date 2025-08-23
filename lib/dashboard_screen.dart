// lib/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'models/inventory_item_model.dart';
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
  List<InventoryItemGroup> _searchResults = [];

  // Data dummy kita sekarang menggunakan model InventoryItemGroup
  final List<InventoryItemGroup> _allItemGroups = [
    InventoryItemGroup(
      itemName: 'Tomat',
      imagePath: 'assets/images/tomato.png',
      batches: [
        Batch(
            id: 'tomat1',
            entryDate: DateTime(2025, 8, 8),
            quantity: 3,
            predictedShelfLife: 3),
        Batch(
            id: 'tomat2',
            entryDate: DateTime(2025, 8, 9),
            quantity: 2,
            predictedShelfLife: 4),
      ],
    ),
    InventoryItemGroup(
      itemName: 'Selada',
      imagePath: 'assets/images/lettuce.png',
      batches: [
        Batch(
            id: 'selada1',
            entryDate: DateTime(2025, 8, 7),
            quantity: 1,
            predictedShelfLife: 5)
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final results = _allItemGroups
        .where((group) =>
            group.itemName.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() => _searchResults = results);
  }

  @override
  Widget build(BuildContext context) {
    final bool showSearchResults = _searchController.text.isNotEmpty;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage('assets/images/profile.png')),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Halo,\nNeira!',
                          style: TextStyle(
                              color: Color(0xFF3A592C),
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              height: 1.2)),
                      const SizedBox(height: 4),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(
                              color: Color(0xFF5D5D5D),
                              fontSize: 14,
                              fontFamily: 'Poppins'),
                          children: <TextSpan>[
                            TextSpan(text: 'Selamat Datang di '),
                            TextSpan(
                                text: 'FreshLens AI',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF769C3E))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Telusuri inventaris Anda...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide.none),
                ),
              ),
              if (showSearchResults)
                _buildSearchResults()
              else
                _buildDashboardContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final itemGroup = _searchResults[index];
        return ListTile(
          leading:
              CircleAvatar(backgroundImage: AssetImage(itemGroup.imagePath)),
          title: Text(itemGroup.itemName),
          subtitle: Text('Total: ${itemGroup.totalQuantity} buah'),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(itemGroup: itemGroup),
                ));
          },
        );
      },
    );
  }

  Widget _buildDashboardContent() {
    final previewItems = _allItemGroups.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Row(
          children: [
            Icon(Icons.wb_sunny_outlined, color: Color(0xFF4E5D49)),
            SizedBox(width: 8),
            Text('Segera Habiskan',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F))),
          ],
        ),
        const SizedBox(height: 16),
        const UrgentItemCard(
            itemIcon: FontAwesomeIcons.lemon,
            itemName: 'Pisang',
            daysLeft: 'Sisa 1 hari'),
        const SizedBox(height: 12),
        const UrgentItemCard(
            itemIcon: FontAwesomeIcons.carrot,
            itemName: 'Wortel',
            daysLeft: 'Sisa 3 hari'),
        const SizedBox(height: 30),
        const Row(
          children: [
            Expanded(
                child: SensorCard(
                    title: 'Suhu',
                    icon: Icons.thermostat,
                    value: '24',
                    unit: '° C',
                    status: 'Normal')),
            SizedBox(width: 16),
            Expanded(
                child: SensorCard(
                    title: 'Kelembapan',
                    icon: Icons.water_drop_outlined,
                    value: '65',
                    unit: '%',
                    status: 'Optimal')),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: Color(0xFF4E5D49)),
            const SizedBox(width: 8),
            const Text('Inventaris',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF37474F))),
            const Spacer(),
            TextButton(
                onPressed: widget.onViewAllTapped,
                child: const Text('Lihat semua')),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: previewItems.map((itemGroup) {
            return InventoryListItem(
              itemName: itemGroup.itemName,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          ItemDetailScreen(itemGroup: itemGroup)),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
