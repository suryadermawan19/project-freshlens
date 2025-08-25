// lib/camera_screen.dart

import 'dart:async';
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
  List<CameraDescription>? _cameras;
  CameraController? _controller;
  
  ImageLabeler? _imageLabeler;
  bool _isDetecting = false;
  String _detectedLabel = "Arahkan ke buah atau sayur...";
  Timer? _detectionTimer;

  @override
  void initState() {
    super.initState();
    _initializeAIAndCamera();
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _controller?.stopImageStream();
    _controller?.dispose();
    _imageLabeler?.close();
    super.dispose();
  }

  String _translateLabel(String englishLabel) {
    final lowerLabel = englishLabel.toLowerCase();
    const dictionary = {
      'apple': 'Apel', 'banana': 'Pisang', 'orange': 'Jeruk', 'tomato': 'Tomat',
      'lettuce': 'Selada', 'carrot': 'Wortel', 'spinach': 'Bayam', 'broccoli': 'Brokoli',
      'potato': 'Kentang', 'chili pepper': 'Cabai',
    };
    return dictionary[lowerLabel] ?? englishLabel;
  }

  Future<void> _initializeAIAndCamera() async {
    final options = ImageLabelerOptions(confidenceThreshold: 0.75);
    _imageLabeler = ImageLabeler(options: options);

    _cameras = await availableCameras();
    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();

    _controller!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  void _processCameraImage(CameraImage image) {
    if (_isDetecting || !mounted || _imageLabeler == null) return;
    _isDetecting = true;
    
    final inputImage = _inputImageFromCameraImage(image);
    
    if (inputImage != null) {
      _imageLabeler!.processImage(inputImage).then((labels) {
        if (labels.isNotEmpty && mounted) {
          final translatedLabel = _translateLabel(labels.first.label);
          setState(() {
            _detectedLabel = translatedLabel;
          });
        }
      }).whenComplete(() {
          _detectionTimer = Timer(const Duration(milliseconds: 500), () {
            if (mounted) {
              _isDetecting = false;
            }
          });
      });
    } else {
      _isDetecting = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

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
    if (format == null || (Platform.isAndroid && format != InputImageFormat.nv21) || (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.length != 1) return null;
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

  void _captureAndConfirm() async {
    if (_detectedLabel.contains("Arahkan") || _controller == null || !_controller!.value.isInitialized) return;
    
    await _controller!.stopImageStream();
    final image = await _controller!.takePicture();
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmItemScreen(
          imagePath: image.path,
          detectedItemName: _detectedLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(child: CameraPreview(_controller!)),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                // PERBAIKAN DI SINI
                colors: [Colors.black.withAlpha(153), Colors.transparent, Colors.black.withAlpha(204)],
                stops: const [0.0, 0.4, 0.8],
              ),
            ),
          ),
          Positioned(
            top: 60,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                // PERBAIKAN DI SINI
                color: Colors.black.withAlpha(128),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _detectedLabel,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            child: FloatingActionButton.large(
              onPressed: _captureAndConfirm,
              backgroundColor: Colors.white,
              child: const Icon(Icons.camera_alt, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}