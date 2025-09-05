// lib/providers/loading_provider.dart

import 'package:flutter/material.dart';

/// Provider untuk mengelola state loading secara global di seluruh aplikasi.
///
/// Ini membantu memusatkan logika untuk menampilkan atau menyembunyikan
/// indikator loading, sehingga widget tidak perlu lagi mengelola state `_isLoading`
/// secara lokal menggunakan `setState`.
class LoadingProvider with ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Memulai state loading dan memberi tahu listener.
  void startLoading() {
    if (_isLoading) return; // Mencegah pemanggilan berulang yang tidak perlu
    _isLoading = true;
    notifyListeners();
  }

  /// Menghentikan state loading dan memberi tahu listener.
  void stopLoading() {
    if (!_isLoading) return; // Mencegah pemanggilan berulang yang tidak perlu
    _isLoading = false;
    notifyListeners();
  }
}