// lib/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/camera_screen.dart'; // Akan kita buat nanti
import 'package:freshlens_ai_app/education_screen.dart';
import 'package:freshlens_ai_app/home_content.dart';
import 'package:freshlens_ai_app/inventory_screen.dart';
import 'package:freshlens_ai_app/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // [LANGKAH 6.1] Siapkan daftar halaman yang akan ditampilkan
  static const List<Widget> _pages = <Widget>[
    HomeContent(), // Index 0
    EducationScreen(), // Index 1
    InventoryScreen(), // Index 2
    ProfileScreen(), // Index 3
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [LANGKAH 6.2] Tampilkan halaman sesuai index yang dipilih
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // [LANGKAH 6.3] Floating Action Button (FAB) di tengah
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const CameraScreen()));
        },
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 2.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // [LANGKAH 6.4] Bottom Navigation Bar sesuai desain
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(), // Membuat lengkungan untuk FAB
        notchMargin: 8.0, // Jarak antara FAB dan bar
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildNavItem(
                index: 0,
                label: 'Beranda',
                activeIcon: Icons.home,
                inactiveIcon: Icons.home_outlined),
            _buildNavItem(
                index: 1,
                label: 'Edukasi',
                activeIcon: Icons.menu_book,
                inactiveIcon: Icons.menu_book_outlined),
            const SizedBox(
                width: 48), // Memberi ruang kosong di tengah untuk FAB
            _buildNavItem(
                index: 2,
                label: 'Inventaris',
                activeIcon: Icons.inventory_2,
                inactiveIcon: Icons.inventory_2_outlined),
            _buildNavItem(
                index: 3,
                label: 'Profil',
                activeIcon: Icons.person,
                inactiveIcon: Icons.person_outline_rounded),
          ],
        ),
      ),
    );
  }

  // [LANGKAH 6.5] Widget helper untuk membuat setiap item navigasi
  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final bool isSelected = _selectedIndex == index;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;
    return Expanded(
      child: InkWell(
        onTap: () => _onItemTapped(index),
        borderRadius: BorderRadius.circular(30), // Efek ripple yang membulat
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(isSelected ? activeIcon : inactiveIcon,
                  color: color, size: 24),
              const SizedBox(height: 4), // Jarak antara ikon dan label
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
