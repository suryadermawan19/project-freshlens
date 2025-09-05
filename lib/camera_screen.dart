// lib/camera_screen.dart (Cloud Vision → langsung ke ConfirmItemScreen)
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'confirm_item_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _busy = false;

  // pakai region Jakarta biar gak NOT_FOUND
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'asia-southeast2');

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.medium,
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
    if (_controller == null || !_controller!.value.isInitialized || _busy) return;

    setState(() => _busy = true);
    // simpan navigator supaya aman dari use_build_context_synchronously
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1) Ambil foto
      final picture = await _controller!.takePicture();
      final imagePath = picture.path;

      // 2) Base64 (bisa di-compress/resize dulu kalau perlu)
      final bytes = await File(imagePath).readAsBytes();
      final b64 = base64Encode(bytes);

      // 3) Panggil Cloud Function annotate_image
      final callable = _functions.httpsCallable('annotate_image');
      final resp = await callable.call(<String, dynamic>{'image': b64});

      final label = (resp.data is Map && resp.data['label'] != null)
          ? resp.data['label'].toString()
          : 'Tidak terdeteksi';

      // 4) Langsung pindah ke ConfirmItemScreen sambil bawa foto + label
      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConfirmItemScreen(
            imagePath: imagePath,
            detectedItemName: label, // mis: "Apple", "Orange", dll.
          ),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Gagal scan: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: (_controller == null || !_controller!.value.isInitialized)
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(child: CameraPreview(_controller!)),
                Positioned(
                  bottom: 50,
                  child: FloatingActionButton.extended(
                    onPressed: _busy ? null : _scanAndConfirm,
                    backgroundColor: Colors.white,
                    label: _busy
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Text('Scan', style: TextStyle(color: Colors.green)),
                    icon: _busy ? null : const Icon(Icons.check, color: Colors.green),
                  ),
                ),
              ],
            ),
    );
  }
}
