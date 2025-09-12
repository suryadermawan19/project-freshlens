// lib/camera_screen.dart

import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:freshlens_ai_app/confirm_item_screen.dart'; // Halaman berikutnya

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isBusy = false;

  // Pastikan region sudah benar
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No camera found on this device.');
      }
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal inisialisasi kamera: $e')),
      );
    }
  }

  Future<void> _scanAndConfirm() async {
    if (_controller == null || !_controller!.value.isInitialized || _isBusy) return;

    setState(() => _isBusy = true);
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Ambil gambar
      final picture = await _controller!.takePicture();
      final imagePath = picture.path;

      // 2. Encode gambar ke Base64
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // 3. Panggil Cloud Function untuk deteksi objek
      final callable = _functions.httpsCallable('annotate_image');
      final response = await callable.call(<String, dynamic>{'image': base64Image});

      // Ambil label dari response, default ke 'Tidak Dikenali'
      final detectedLabel = (response.data is Map && response.data['label'] != null)
          ? response.data['label'].toString()
          : 'Tidak Dikenali';

      // 4. Navigasi ke halaman konfirmasi
      await navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConfirmItemScreen(
            imagePath: imagePath,
            detectedItemName: detectedLabel,
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal memproses gambar: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Tampilan kamera mengisi seluruh layar
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // Tombol kembali di pojok kiri atas
          Positioned(
            top: 50,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          
          // Tombol Scan di bawah
          Positioned(
            bottom: 50,
            child: FloatingActionButton.large(
              onPressed: _isBusy ? null : _scanAndConfirm,
              child: _isBusy
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.camera_alt),
            ),
          ),
        ],
      ),
    );
  }
}