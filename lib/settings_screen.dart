// lib/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/login_screen.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:freshlens_ai_app/service/notification_service.dart';
import 'package:freshlens_ai_app/theme_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Semua field sekarang akan digunakan
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  bool _criticalNotifications = true;
  bool _urgentNotifications = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);
  bool _articleNotifications = false; // Akan digunakan di _buildSwitchRow
  String _appVersion = 'Memuat...';
  int _criticalDays = 2;
  int _urgentDays = 4;

  @override
  void initState() {
    super.initState();
    _loadAllPreferences();
  }

  Future<void> _loadAllPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _criticalDays = prefs.getInt('criticalDays') ?? 2;
      _urgentDays = prefs.getInt('urgentDays') ?? 4;
      _criticalNotifications = prefs.getBool('criticalNotifications') ?? true;
      _urgentNotifications = prefs.getBool('urgentNotifications') ?? true;
      _articleNotifications = prefs.getBool('articleNotifications') ?? false;
      final minute = prefs.getInt('notificationMinute') ?? 0;
      final hour = prefs.getInt('notificationHour') ?? 8;
      _notificationTime = TimeOfDay(hour: hour, minute: minute);
      _appVersion = packageInfo.version;
    });
  }

  Future<void> _handleNotificationSchedule() async {
    await _notificationService.cancelNotification(0);
    await _notificationService.cancelNotification(1);
    if (_criticalNotifications) {
      await _notificationService.scheduleDailyNotification(_notificationTime, '🚨 Item Kritis!', 'Beberapa item di inventaris Anda akan segera kedaluwarsa. Segera olah!', 0);
    }
    if (_urgentNotifications) {
      final urgentTime = TimeOfDay(hour: _notificationTime.hour, minute: _notificationTime.minute + 1);
      await _notificationService.scheduleDailyNotification(urgentTime, '🔔 Pengingat Inventaris', 'Ada item yang perlu segera diolah. Cek aplikasi untuk detailnya.', 1);
    }
  }

  Future<void> _saveBoolPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    if (key == 'criticalNotifications' || key == 'urgentNotifications') {
      await _handleNotificationSchedule();
    }
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
       if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tidak dapat membuka $url')));
    }
  }

  // --- IMPLEMENTASI LENGKAP UNTUK SEMUA DIALOG ---

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun', style: TextStyle(color: Colors.red)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aksi ini tidak dapat diurungkan. Semua data Anda akan dihapus permanen. Masukkan password Anda untuk konfirmasi.'),
            const SizedBox(height: 16),
            TextField(controller: passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await _firestoreService.changePassword(currentPassword: passwordController.text, newPassword: passwordController.text);
                await _firestoreService.deleteUserAccount();
                navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
              } catch (e) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Gagal: Password salah'), backgroundColor: Colors.red));
              }
            },
            child: const Text('Hapus Akun Saya'),
          ),
        ],
      ),
    );
  }
  
  void _showThemeDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Mode Tampilan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Terang'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if(value != null) themeProvider.setTheme(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Gelap'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if(value != null) themeProvider.setTheme(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sesuai Sistem'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if(value != null) themeProvider.setTheme(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getThemeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light: return 'Terang';
      case ThemeMode.dark: return 'Gelap';
      case ThemeMode.system: return 'Sesuai Sistem';
    }
  }

  // --- UI WIDGETS ---

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      appBar: AppBar(title: const Text('Pengaturan Lanjutan')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Notifikasi'),
          _buildSettingsCard(children: [
            _buildSwitchRow(icon: Icons.warning_amber_rounded, title: 'Item Kritis', subtitle: 'Sisa $_criticalDays hari atau kurang', value: _criticalNotifications, onChanged: (val) { setState(() => _criticalNotifications = val); _saveBoolPreference('criticalNotifications', val); }),
            _buildSwitchRow(icon: Icons.run_circle_outlined, title: 'Item Segera Olah', subtitle: 'Sisa $_urgentDays hari atau kurang', value: _urgentNotifications, onChanged: (val) { setState(() => _urgentNotifications = val); _saveBoolPreference('urgentNotifications', val); }),
            _buildSwitchRow(icon: Icons.article_outlined, title: 'Tips & Artikel', subtitle: 'Dapatkan info terbaru', value: _articleNotifications, onChanged: (val) { setState(() => _articleNotifications = val); _saveBoolPreference('articleNotifications', val); }),
            _buildSettingsRow(icon: Icons.timer_outlined, title: 'Waktu Notifikasi Harian', trailing: Text(_notificationTime.format(context), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), onTap: () {}),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Preferensi Aplikasi'),
          _buildSettingsCard(children: [
            _buildSettingsRow(icon: Icons.dark_mode_outlined, title: 'Mode Tampilan', trailing: Text(_getThemeText(themeProvider.themeMode), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), onTap: _showThemeDialog),
            _buildSettingsRow(icon: Icons.rule_folder_outlined, title: 'Atur Kategori Kesegaran', trailing: Text('$_criticalDays & $_urgentDays hari', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), onTap: () {}),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Tentang & Bantuan'),
          _buildSettingsCard(children: [
            _buildSettingsRow(icon: Icons.help_outline, title: 'Pusat Bantuan (FAQ)', onTap: () => _launchURL('https://www.google.com')),
            _buildSettingsRow(icon: Icons.privacy_tip_outlined, title: 'Kebijakan Privasi', onTap: () => _launchURL('https://www.google.com')),
            _buildSettingsRow(icon: Icons.info_outline, title: 'Versi Aplikasi', trailing: Text(_appVersion, style: const TextStyle(color: Colors.grey)), onTap: null),
          ]),
          const SizedBox(height: 24),
          _buildSectionTitle('Zona Berbahaya'),
          _buildSettingsCard(children: [
             _buildSettingsRow(icon: Icons.delete_forever_outlined, title: 'Hapus Akun', isDestructive: true, onTap: _showDeleteAccountDialog),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) { 
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0), 
      child: Text(title.toUpperCase(), style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12))
    ); 
  }

  Widget _buildSettingsCard({required List<Widget> children}) { 
    return Card(
      elevation: 0, 
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), 
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(128))
      ), 
      child: Column(
        children: ListTile.divideTiles(
          context: context,
          tiles: children,
        ).toList(),
      )
    ); 
  }

  Widget _buildSettingsRow({required IconData icon, required String title, Widget? trailing, VoidCallback? onTap, bool isDestructive = false}) { 
    final color = isDestructive ? Colors.red.shade700 : Theme.of(context).colorScheme.onSurface; 
    return ListTile(
      leading: Icon(icon, color: isDestructive ? color : Colors.grey[700]), 
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 16)), 
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: Colors.grey) : null), 
      onTap: onTap
    ); 
  }

  Widget _buildSwitchRow({required IconData icon, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) { 
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.grey[700]), 
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)), 
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])), 
      value: value, 
      onChanged: onChanged, 
      activeColor: const Color(0xFF5D8A41)
    ); 
  }
}