// lib/qr_scanner_screen.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // Guard: pastikan ada barcode & bersihkan whitespace
    if (capture.barcodes.isEmpty) {
      _showErrorAndResume('QR code tidak terbaca.');
      return;
    }
    final raw = capture.barcodes.first.rawValue?.trim();
    if (raw == null || raw.isEmpty) {
      _showErrorAndResume('QR code tidak valid.');
      return;
    }
    final deviceId = raw;

    try {
      // Pastikan user login (anon juga boleh)
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        await auth.signInAnonymously();
      }

      // Panggil Callable Function di region asia-southeast2
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast2');
      final callable = functions.httpsCallable('registerDevice');

      final result = await callable.call({'deviceId': deviceId});
      final data = (result.data as Map?)?.cast<String, dynamic>() ?? {};
      final message = data['message']?.toString() ?? 'Perangkat berhasil terdaftar.';

      _showSuccessAndPop(message);
    } on FirebaseFunctionsException catch (e) {
      // e.code bisa: unauthenticated, invalid-argument, not-found, internal, dll.
      _showErrorAndResume('Gagal (${e.code}): ${e.message ?? 'Terjadi kesalahan.'}');
    } catch (_) {
      _showErrorAndResume('Terjadi kesalahan tidak terduga.');
    }
  }

  void _showErrorAndResume(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    setState(() => _isProcessing = false); // Siap scan lagi
  }

  void _showSuccessAndPop(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pindai QR Perangkat')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.15), // perbaikan dari withValues
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
