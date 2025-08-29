// lib/camera_screen.dart

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import 'confirm_item_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  ImageLabeler? _imageLabeler;

  bool _isDetecting = false;
  String _detectedLabel = 'Mengarahkan kamera ke objek buah...';

  @override
  void initState() {
    super.initState();
    _initializeCameraAndMlKit();
  }

  Future<void> _initializeCameraAndMlKit() async {
    try {
      _cameras = await availableCameras();
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (!mounted) return;

      _controller!.startImageStream((CameraImage image) {
        if (!_isDetecting) {
          _isDetecting = true;
          _processCameraImage(image).whenComplete(() => _isDetecting = false);
        }
      });

      setState(() {});

      final options = ImageLabelerOptions(confidenceThreshold: 0.75);
      _imageLabeler = ImageLabeler(options: options);

    } catch (e) {
      if (mounted) {
        // Jalankan snackbar setelah frame build selesai
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error inisialisasi kamera: $e')),
          );
        });
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_imageLabeler == null) return;

    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) return;

    try {
      final List<ImageLabel> labels = await _imageLabeler!.processImage(inputImage);
      if (labels.isNotEmpty && mounted) {
        setState(() {
          _detectedLabel = labels.first.label;
        });
      }
    } catch (e) {
      // Bisa ditambah logging kalau perlu
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null || _cameras == null) return null;

    final camera = _cameras![0];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation = (sensorOrientation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _imageLabeler?.close();
    super.dispose();
  }

  void _onConfirmPressed() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _controller!.value.isTakingPicture) {
      return;
    }

    final navigator = Navigator.of(context);

    try {
      await _controller?.stopImageStream();
      final image = await _controller!.takePicture();

      navigator.pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConfirmItemScreen(
            imagePath: image.path,
            detectedItemName: _detectedLabel,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengkonfirmasi item: $e')),
        );
      }
      if (mounted && _controller!.value.isInitialized) {
        _controller!.startImageStream((CameraImage image) {
          if (!_isDetecting) {
            _isDetecting = true;
            _processCameraImage(image).whenComplete(() => _isDetecting = false);
          }
        });
      }
    }
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
                  top: 50,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Item Terdeteksi: $_detectedLabel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 50,
                  child: FloatingActionButton.large(
                    onPressed: _onConfirmPressed,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.check, color: Colors.green),
                  ),
                ),
              ],
            ),
    );
  }
}
