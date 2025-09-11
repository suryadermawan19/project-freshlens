// lib/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/camera_screen.dart';
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

  // [DIUBAH] Kita definisikan _pages di dalam initState agar bisa meneruskan fungsi
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      // Kirim fungsi _onItemTapped ke HomeContent
      HomeContent(onViewAllTapped: () => _onItemTapped(2)), // 2 adalah index untuk Inventaris
      const EducationScreen(),
      const InventoryScreen(),
      const ProfileScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
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
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        height: 65,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _buildNavItem(index: 0, label: 'Beranda', activeIcon: Icons.home, inactiveIcon: Icons.home_outlined),
            _buildNavItem(index: 1, label: 'Edukasi', activeIcon: Icons.menu_book, inactiveIcon: Icons.menu_book_outlined),
            const SizedBox(width: 48),
            _buildNavItem(index: 2, label: 'Inventaris', activeIcon: Icons.inventory_2, inactiveIcon: Icons.inventory_2_outlined),
            _buildNavItem(index: 3, label: 'Profil', activeIcon: Icons.person, inactiveIcon: Icons.person_outline_rounded),
          ],
        ),
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(30),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(isSelected ? activeIcon : inactiveIcon, color: color, size: 24),
              const SizedBox(height: 4),
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