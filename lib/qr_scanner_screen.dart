// lib/qr_scanner_screen.dart

import 'package:cloud_functions/cloud_functions.dart';
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
    setState(() {
      _isProcessing = true;
    });

    final String? deviceId = capture.barcodes.first.rawValue;
    if (deviceId == null) {
      _showErrorAndResume('QR code tidak valid.');
      return;
    }

    try {
      final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast2');
      final callable = functions.httpsCallable('registerDevice');
      final result = await callable.call({'deviceId': deviceId});
      
      _showSuccessAndPop(result.data['message']);

    } on FirebaseFunctionsException catch (e) {
      _showErrorAndResume('Gagal: ${e.message}');
    } catch (e) {
      _showErrorAndResume('Terjadi kesalahan tidak terduga.');
    }
  }

  void _showErrorAndResume(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ));
      setState(() {
        _isProcessing = false; // Siap untuk scan lagi
      });
    }
  }
  
  void _showSuccessAndPop(String message) {
     if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ));
        Navigator.of(context).pop();
     }
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
          // Tambahkan overlay atau penanda area scan di sini jika perlu
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
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