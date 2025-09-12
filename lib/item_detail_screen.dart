// lib/item_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:freshlens_ai_app/models/inventory_item_model.dart';
import 'package:freshlens_ai_app/recipe_webview_screen.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:intl/intl.dart';

// Widget untuk status bar kesegaran
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
    final (statusText, statusColor) = switch (daysLeft) {
      <= 2 => ('Kritis', Colors.red.shade600),
      <= 4 => ('Segera Olah', Colors.orange.shade700),
      _ => ('Segar', Colors.green.shade600),
    };
    
    final double percentage = (daysLeft > 0 ? daysLeft.toDouble() / maxShelfLife : 0.0).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Status Kesegaran', style: Theme.of(context).textTheme.titleMedium),
            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 16,
            backgroundColor: statusColor.withAlpha(50),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
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
    _batches.sort((a, b) => a.predictedShelfLife.compareTo(b.predictedShelfLife));
  }
  
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

  void _showQuantityDialog({
    required BuildContext context,
    required Batch batch,
    required String title,
    required String actionLabel,
    required Color actionColor,
    required bool isAdding,
    required Future<void> Function(int quantity) onConfirm,
  }) {
    int selectedQuantity = 1;
    final maxQuantity = isAdding ? 99 : batch.quantity;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Pilih jumlah untuk ${widget.itemGroup.itemName}:'),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: selectedQuantity > 1
                            ? () => setDialogState(() => selectedQuantity--)
                            : null,
                      ),
                      Text('$selectedQuantity', style: Theme.of(context).textTheme.headlineMedium),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: selectedQuantity < maxQuantity
                            ? () => setDialogState(() => selectedQuantity++)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: actionColor),
                  onPressed: () async {
                    final navigator = Navigator.of(ctx);
                    await onConfirm(selectedQuantity);
                    navigator.pop();
                  },
                  child: Text(actionLabel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleMarkAsUsed(Batch batch) {
    _showQuantityDialog(
      context: context,
      batch: batch,
      title: 'Olah Item',
      actionLabel: 'Ya, Olah',
      actionColor: Colors.green,
      isAdding: false,
      onConfirm: (quantity) async {
        await _firestoreService.markAsUsed(batch, quantity);
        if (!mounted) return;
        setState(() {
          final newQuantity = batch.quantity - quantity;
          if (newQuantity <= 0) {
            _batches.remove(batch);
          } else {
            batch.quantity = newQuantity;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statistik diperbarui!'), backgroundColor: Colors.green));
        if (_batches.isEmpty) Navigator.of(context).pop();
      },
    );
  }

  void _handleDiscard(Batch batch) {
    _showQuantityDialog(
      context: context,
      batch: batch,
      title: 'Buang Item',
      actionLabel: 'Ya, Buang',
      actionColor: Colors.red,
      isAdding: false,
      onConfirm: (quantity) async {
        await _firestoreService.discardItems(batch.id, batch.quantity, quantity);
        if (!mounted) return;
        setState(() {
          final newQuantity = batch.quantity - quantity;
          if (newQuantity <= 0) {
            _batches.remove(batch);
          } else {
            batch.quantity = newQuantity;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item dibuang.'), backgroundColor: Colors.red));
        if (_batches.isEmpty) Navigator.of(context).pop();
      },
    );
  }

  void _handleAddItem(Batch batch) {
    _showQuantityDialog(
      context: context,
      batch: batch,
      title: 'Tambah Kuantitas',
      actionLabel: 'Ya, Tambah',
      actionColor: Theme.of(context).primaryColor,
      isAdding: true,
      onConfirm: (quantity) async {
        final newQuantity = batch.quantity + quantity;
        await _firestoreService.updateItemQuantity(batch.id, newQuantity);
        if (!mounted) return;
        setState(() => batch.quantity = newQuantity);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kuantitas diperbarui!'), backgroundColor: Colors.blue));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalQuantity = _batches.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade50,
            Colors.green.shade200,
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(widget.itemGroup.itemName),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black87,
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(context, totalQuantity),
                const SizedBox(height: 24),
                _buildBatchList(context),
                const SizedBox(height: 24),
                _buildStorageTips(context),
                const SizedBox(height: 24),
                _buildRecipeButton(context),
                const SizedBox(height: 24),
              ],
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withAlpha(100),
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, int totalQuantity) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.itemGroup.imagePath,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 40),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.itemGroup.itemName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Kuantitas: $totalQuantity buah',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchList(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Daftar Batch',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Geser kartu ke kiri untuk melihat aksi cepat.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 12),
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
      ],
    );
  }

  Widget _buildBatchCard(BuildContext context, Batch batch, bool isPriority) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.9,
        children: [
          SlidableAction(
            onPressed: (context) => _handleMarkAsUsed(batch),
            backgroundColor: Colors.green.shade600,
            foregroundColor: Colors.white,
            icon: Icons.check_circle_outline,
            label: 'Olah',
          ),
          SlidableAction(
            onPressed: (context) => _handleAddItem(batch),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            icon: Icons.add_circle_outline,
            label: 'Tambah',
          ),
          SlidableAction(
            onPressed: (context) => _handleDiscard(batch),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Buang',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
          ),
        ],
      ),
      child: Card(
        elevation: isPriority ? 2 : 0.5,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isPriority ? Colors.orange.shade700 : Colors.grey.shade300,
            width: isPriority ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isPriority) ...[
                Text(
                  'PRIORITAS UTAMA',
                  style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 12),
              ],
              _buildDetailRow(Icons.calendar_today_outlined, 'Tanggal Masuk', DateFormat('d MMM yyyy').format(batch.entryDate)),
              _buildDetailRow(Icons.thermostat_auto_outlined, 'Kondisi Awal', batch.initialCondition),
              _buildDetailRow(Icons.tag_outlined, 'Jumlah', '${batch.quantity} buah'),
              _buildDetailRow(Icons.hourglass_bottom_outlined, 'Prediksi Sisa Umur', '${batch.predictedShelfLife} hari'),
              const Divider(height: 24),
              FreshnessStatusBar(daysLeft: batch.predictedShelfLife),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(color: Colors.grey[700])),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStorageTips(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.green.withAlpha(40),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.green.shade800),
                const SizedBox(width: 12),
                Text(
                  "Tips Penyimpanan Cerdas",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _getStorageTip(widget.itemGroup.itemName),
              style: TextStyle(color: Colors.green.shade900, height: 1.4),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeButton(BuildContext context) {
    return ElevatedButton.icon(
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
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5D8A41),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Montserrat'),
      ),
    );
  }
}