// lib/item_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:freshlens_ai_app/models/inventory_item_model.dart';
import 'package:freshlens_ai_app/recipe_webview_screen.dart';

// (Widget FreshnessStatusBar tidak berubah)
class FreshnessStatusBar extends StatelessWidget {
  final int daysLeft;
  final int maxShelfLife;

  const FreshnessStatusBar({
    super.key,
    required this.daysLeft,
    this.maxShelfLife = 10,
  });

  @override
  Widget build(BuildContext context) {
    Color barColor;
    String statusText;
    
    if (daysLeft <= 2) {
      barColor = Colors.red.shade400;
      statusText = 'Kritis';
    } else if (daysLeft <= 4) {
      barColor = Colors.orange.shade400;
      statusText = 'Segera Olah';
    } else {
      barColor = Colors.green.shade400;
      statusText = 'Segar';
    }
    
    final double percentage = (daysLeft > 0 ? daysLeft.toDouble() / maxShelfLife : 0.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Status', style: TextStyle(color: Colors.grey[700])),
            Text(statusText, style: TextStyle(color: barColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }
}

class ItemDetailScreen extends StatefulWidget {
  final InventoryItemGroup itemGroup;

  const ItemDetailScreen({
    super.key,
    required this.itemGroup,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late List<Batch> _batches;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _batches = List.from(widget.itemGroup.batches);
  }
  
  // --- SEMUA FUNGSI HELPER YANG LENGKAP ---

  String _getStorageTip(String itemName) {
    String lowerCaseItemName = itemName.toLowerCase();
    const tips = {
      'tomat': 'Simpan tomat di suhu ruang dan jauhkan dari sinar matahari langsung. Jangan simpan di kulkas karena akan merusak teksturnya.',
      'selada': 'Bungkus selada dengan kertas tisu, masukkan ke wadah kedap udara, lalu simpan di laci kulkas.',
      'pisang': 'Simpan pisang di suhu ruang. Untuk memperlambat pematangan, bungkus pangkal tandan pisang dengan plastik.',
      'wortel': 'Potong bagian atas wortel (daunnya). Simpan di dalam kantong plastik yang sedikit terbuka di laci kulkas.',
    };
    return tips[lowerCaseItemName] ?? 'Pastikan item disimpan di tempat yang sejuk dan kering untuk menjaga kesegarannya.';
  }
  
  void _showUsedConfirmation(Batch batch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: Text('Anda yakin sudah mengolah ${batch.quantity} buah ${widget.itemGroup.itemName}? Aksi ini akan menambah statistik Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => _isLoading = true);
              final navigator = Navigator.of(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final rootNavigator = Navigator.of(context);

              await _firestoreService.markAsUsed(batch);

              if(!mounted) return;
              setState(() {
                _batches.remove(batch);
                _isLoading = false;
              });

              navigator.pop();
              scaffoldMessenger.showSnackBar(
                const SnackBar(content: Text('Statistik berhasil diperbarui!'), backgroundColor: Colors.green),
              );

              if (_batches.isEmpty) {
                rootNavigator.pop();
              }
            },
            child: const Text('Ya, Sudah'),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(Batch batch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Batch (Dibuang)?', style: TextStyle(color: Colors.red)),
        content: Text('Aksi ini menandakan ${batch.quantity} buah ${widget.itemGroup.itemName} terbuang dan tidak akan menambah statistik Anda.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final rootNavigator = Navigator.of(context);

              await _firestoreService.deleteItem(batch.id);
              
              if(!mounted) return;
              setState(() => _batches.remove(batch));
              
              navigator.pop();
              scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Batch berhasil dihapus'), backgroundColor: Colors.red));
              
              if (_batches.isEmpty) {
                rootNavigator.pop();
              }
            },
            child: const Text('Ya, Hapus & Buang'),
          ),
        ],
      ),
    );
  }

  void _performSnooze(Batch batch, int days) async {
    setState(() => _isLoading = true);
    final newShelfLife = batch.predictedShelfLife + days;
    await _firestoreService.updateItem(batch.id, {'predictedShelfLife': newShelfLife});

    if(!mounted) return;
    setState(() {
      final index = _batches.indexOf(batch);
      _batches[index] = Batch(
        id: batch.id, entryDate: batch.entryDate, quantity: batch.quantity,
        predictedShelfLife: newShelfLife, initialCondition: batch.initialCondition,
      );
      _isLoading = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Notifikasi ditunda $days hari')));
  }

  void _performEditQuantity(Batch batch, int newQuantity) async {
    setState(() => _isLoading = true);
    await _firestoreService.updateItem(batch.id, {'quantity': newQuantity});
    
    if(!mounted) return;
    setState(() {
      final index = _batches.indexOf(batch);
      _batches[index] = Batch(
        id: batch.id, entryDate: batch.entryDate, quantity: newQuantity,
        predictedShelfLife: batch.predictedShelfLife, initialCondition: batch.initialCondition,
      );
      _isLoading = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kuantitas berhasil diperbarui')));
  }
  
  void _showSnoozeDialog(Batch batch) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFFAF8F1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.snooze_outlined, color: Colors.grey.shade700),
                  const SizedBox(width: 8),
                  Text('Tunda Notifikasi Untuk...?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSnoozeOptionButton(ctx, batch, 1, '1 Hari'),
              const SizedBox(height: 12),
              _buildSnoozeOptionButton(ctx, batch, 2, '2 Hari'),
              const SizedBox(height: 12),
              _buildSnoozeOptionButton(ctx, batch, 3, '3 Hari'),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Batal', style: TextStyle(color: Colors.grey.shade600))),
            ],
          ),
      ),
    );
  }

  Widget _buildSnoozeOptionButton(BuildContext ctx, Batch batch, int days, String label) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _performSnooze(batch, days);
          Navigator.of(ctx).pop();
        },
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B8E9A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 2),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  void _showEditQuantityDialog(Batch batch) {
    showDialog(
      context: context,
      builder: (ctx) {
        int currentQuantity = batch.quantity;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFFAF8F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, color: Colors.grey.shade700),
                        const SizedBox(width: 8),
                        Text('Edit Kuantitas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey.shade800)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle_outline, size: 32), onPressed: () => {if (currentQuantity > 1) setDialogState(() => currentQuantity--)}),
                        const SizedBox(width: 24),
                        Text('$currentQuantity', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 24),
                        IconButton(icon: const Icon(Icons.add_circle_outline, size: 32), onPressed: () => setDialogState(() => currentQuantity++)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            _performEditQuantity(batch, currentQuantity);
                            Navigator.of(ctx).pop();
                          },
                          child: const Text('Simpan'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _batches.sort((a, b) => a.predictedShelfLife.compareTo(b.predictedShelfLife));
    final totalQuantity = _batches.fold(0, (sum, item) => sum + item.quantity);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      appBar: AppBar(
        title: Text(widget.itemGroup.itemName),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.itemGroup.imagePath,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          return progress == null ? child : const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 100);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.itemGroup.itemName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Total: $totalQuantity buah', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Daftar Batch (Geser ke kiri untuk aksi)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListView.separated(
                  itemCount: _batches.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final batch = _batches[index];
                    return _buildBatchCard(context, batch, index == 0);
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(FontAwesomeIcons.lightbulb, size: 18),
                  label: const Text('Cari Ide Olahan'),
                  onPressed: () {
                    final searchTerm = Uri.encodeComponent(widget.itemGroup.itemName);
                    final searchUrl = 'https://cookpad.com/id/cari/$searchTerm';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RecipeWebviewScreen(
                          initialUrl: searchUrl,
                          itemTitle: widget.itemGroup.itemName,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5D8A41), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 24),
                _buildSmartFeaturesSection(widget.itemGroup.itemName),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBatchCard(BuildContext context, Batch batch, bool isPriority) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.8,
        children: [
          CustomSlidableAction(
            onPressed: (context) {
              Slidable.of(context)?.close();
              _showUsedConfirmation(batch);
            },
            backgroundColor: Colors.green.shade600,
            borderRadius: BorderRadius.circular(16),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(height: 4),
              Text('Olah', style: TextStyle(fontSize: 12, color: Colors.white))
            ]),
          ),
          CustomSlidableAction(
            onPressed: (context) {
              Slidable.of(context)?.close();
              _showEditQuantityDialog(batch);
            },
            backgroundColor: Colors.blue.shade700,
            borderRadius: BorderRadius.circular(16),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.edit_outlined, color: Colors.white), SizedBox(height: 4), Text('Edit', style: TextStyle(fontSize: 12, color: Colors.white))]),
          ),
          CustomSlidableAction(
            onPressed: (context) {
              Slidable.of(context)?.close();
              _showSnoozeDialog(batch);
            },
            backgroundColor: Colors.orange.shade700,
            borderRadius: BorderRadius.circular(16),
            child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.snooze_outlined, color: Colors.white), SizedBox(height: 4), Text('Tunda', style: TextStyle(fontSize: 12, color: Colors.white))]),
          ),
          CustomSlidableAction(
            onPressed: (context) {
              Slidable.of(context)?.close();
              _showDeleteConfirmation(batch);
            },
            backgroundColor: Colors.red.shade700,
            borderRadius: BorderRadius.circular(16),
             child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.delete_outline, color: Colors.white), SizedBox(height: 4), Text('Buang', style: TextStyle(fontSize: 12, color: Colors.white))]),
          ),
        ],
      ),
      child: Card(
        elevation: isPriority ? 4 : 1,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: isPriority ? Colors.orange.shade700 : Colors.grey.shade300, width: isPriority ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPriority) ...[
                const Text('[PRIORITAS] GUNAKAN DULU!', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
              ],
              _buildDetailRow(Icons.calendar_today_outlined, 'Dibeli', '${batch.entryDate.day}/${batch.entryDate.month}/${batch.entryDate.year}'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.thermostat_auto_outlined, 'Kondisi Awal', batch.initialCondition),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.hourglass_bottom_outlined, 'Sisa Umur', '${batch.predictedShelfLife} hari'),
              const SizedBox(height: 12),
              _buildDetailRow(Icons.format_list_numbered, 'Jumlah', '${batch.quantity} buah'),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              FreshnessStatusBar(daysLeft: batch.predictedShelfLife),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: Colors.grey[700])),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSmartFeaturesSection(String itemName) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      color: Colors.green.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green.shade800),
                const SizedBox(width: 8),
                Text("Tips Penyimpanan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _getStorageTip(itemName),
              style: TextStyle(color: Colors.green.shade900),
            )
          ],
        ),
      ),
    );
  }
}