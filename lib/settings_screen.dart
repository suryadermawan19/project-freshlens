// lib/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/login_screen.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
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
  final FirestoreService _firestoreService = FirestoreService();

  // State untuk notifikasi
  bool _criticalNotifications = true;
  bool _urgentNotifications = true;
  TimeOfDay _notificationTime = const TimeOfDay(hour: 8, minute: 0);
  bool _articleNotifications = false;
  
  // State untuk versi aplikasi
  String _appVersion = 'Memuat...';

  // State untuk ambang batas hari
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

  Future<void> _saveBoolPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka $url')),
      );
    }
  }
  
  Future<void> _selectNotificationTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _notificationTime,
    );

    if (pickedTime != null && pickedTime != _notificationTime) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notificationHour', pickedTime.hour);
      await prefs.setInt('notificationMinute', pickedTime.minute);
      setState(() {
        _notificationTime = pickedTime;
      });
    }
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
                if (value != null) themeProvider.setTheme(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Gelap'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) themeProvider.setTheme(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Sesuai Sistem'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) themeProvider.setTheme(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThresholdDialog() {
    double tempCriticalDays = _criticalDays.toDouble();
    double tempUrgentDays = _urgentDays.toDouble();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Atur Kategori'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Kritis: ${tempCriticalDays.toInt()} hari atau kurang'),
                  Slider(
                    value: tempCriticalDays,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: tempCriticalDays.toInt().toString(),
                    onChanged: (value) {
                      setDialogState(() {
                        tempCriticalDays = value;
                        if (tempUrgentDays < tempCriticalDays) {
                          tempUrgentDays = tempCriticalDays;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Segera Olah: ${tempUrgentDays.toInt()} hari atau kurang'),
                  Slider(
                    value: tempUrgentDays,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: tempUrgentDays.toInt().toString(),
                    onChanged: (value) {
                      setDialogState(() {
                        tempUrgentDays = value;
                        if (tempCriticalDays > tempUrgentDays) {
                          tempCriticalDays = tempUrgentDays;
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setInt('criticalDays', tempCriticalDays.toInt());
                    await prefs.setInt('urgentDays', tempUrgentDays.toInt());
                    
                    if (!mounted) return;
                    setState(() {
                      _criticalDays = tempCriticalDays.toInt();
                      _urgentDays = tempUrgentDays.toInt();
                    });
                    
                    navigator.pop();
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Saat Ini'),
                validator: (val) => val!.isEmpty ? 'Tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru'),
                validator: (val) => val!.length < 6 ? 'Minimal 6 karakter' : null,
              ),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru'),
                validator: (val) => val != newPasswordController.text ? 'Password tidak cocok' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                try {
                  await _firestoreService.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('Password berhasil diubah'), backgroundColor: Colors.green),
                  );
                } catch (e) {
                  navigator.pop();
                  scaffoldMessenger.showSnackBar(
                    SnackBar(content: Text('Gagal: ${e.toString()}'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

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
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              if (passwordController.text.isEmpty) return;
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              try {
                await _firestoreService.changePassword(
                    currentPassword: passwordController.text,
                    newPassword: passwordController.text);
                
                await _firestoreService.deleteUserAccount();
                
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                navigator.pop();
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text('Gagal: Password salah'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Hapus Akun Saya'),
          ),
        ],
      ),
    );
  }

  String _getThemeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Terang';
      case ThemeMode.dark:
        return 'Gelap';
      case ThemeMode.system:
        return 'Sesuai Sistem';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildSectionTitle('Akun & Keamanan'),
          _buildSettingsCard(
            children: [
              _buildSettingsRow(
                icon: Icons.lock_outline,
                title: 'Ubah Password',
                onTap: _showChangePasswordDialog,
              ),
              const Divider(height: 1),
              _buildSettingsRow(
                icon: Icons.delete_outline,
                title: 'Hapus Akun',
                isDestructive: true,
                onTap: _showDeleteAccountDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Notifikasi'),
          _buildSettingsCard(
            children: [
              _buildSwitchRow(
                icon: Icons.warning_amber_rounded,
                title: 'Item Kritis',
                subtitle: 'Sisa umur $_criticalDays hari atau kurang',
                value: _criticalNotifications,
                onChanged: (val) {
                  setState(() => _criticalNotifications = val);
                  _saveBoolPreference('criticalNotifications', val);
                },
              ),
              const Divider(height: 1),
              _buildSwitchRow(
                icon: Icons.run_circle_outlined,
                title: 'Item Segera Olah',
                subtitle: 'Sisa umur $_urgentDays hari atau kurang',
                value: _urgentNotifications,
                onChanged: (val) {
                  setState(() => _urgentNotifications = val);
                  _saveBoolPreference('urgentNotifications', val);
                },
              ),
              const Divider(height: 1),
              _buildSettingsRow(
                icon: Icons.timer_outlined,
                title: 'Waktu Notifikasi Harian',
                trailing: Text(
                  _notificationTime.format(context),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: _selectNotificationTime,
              ),
               const Divider(height: 1),
              _buildSwitchRow(
                icon: Icons.article_outlined,
                title: 'Tips & Artikel',
                subtitle: 'Dapatkan info terbaru dari kami',
                value: _articleNotifications,
                onChanged: (val) {
                  setState(() => _articleNotifications = val);
                  _saveBoolPreference('articleNotifications', val);
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Preferensi Aplikasi'),
          _buildSettingsCard(
            children: [
              _buildSettingsRow(
                icon: Icons.dark_mode_outlined,
                title: 'Mode Gelap',
                trailing: Text(_getThemeText(themeProvider.themeMode), style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: _showThemeDialog,
              ),
              const Divider(height: 1),
              _buildSettingsRow(
                icon: Icons.rule_folder_outlined,
                title: 'Atur Kategori',
                trailing: Text('$_criticalDays & $_urgentDays hari', style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: _showThresholdDialog,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Tentang & Bantuan'),
          _buildSettingsCard(
            children: [
               _buildSettingsRow(
                icon: Icons.help_outline,
                title: 'Pusat Bantuan (FAQ)',
                onTap: () => _launchURL('https://www.google.com'),
              ),
              const Divider(height: 1),
              _buildSettingsRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Kebijakan Privasi',
                onTap: () => _launchURL('https://www.google.com'),
              ),
               const Divider(height: 1),
              _buildSettingsRow(
                icon: Icons.description_outlined,
                title: 'Syarat & Ketentuan',
                onTap: () => _launchURL('https://www.google.com'),
              ),
              const Divider(height: 1),
              _buildSettingsRow(
                icon: Icons.info_outline,
                title: 'Versi Aplikasi',
                trailing: Text(_appVersion, style: const TextStyle(color: Colors.grey)),
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey[600])),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF5D8A41),
    );
  }
}