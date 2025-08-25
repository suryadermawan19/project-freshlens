// lib/service/firestore_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Mendapatkan UID pengguna yang sedang login.
  /// Akan throw exception jika tidak ada pengguna yang login.
  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Pengguna belum login.");
    }
    return user.uid;
  }

  // --- FUNGSI PROFIL PENGGUNA ---

  /// Membuat dokumen profil untuk pengguna baru.
  /// Ini akan dipanggil setelah registrasi dan pengisian biodata.
  Future<void> createUserProfile({
    required String name,
    required int age,
    required String occupation,
  }) async {
    await _db.collection('users').doc(_uid).set({
      'name': name,
      'age': age,
      'occupation': occupation,
      'email': _auth.currentUser?.email, // Simpan email untuk referensi
      'profileImageUrl': null, // Akan diisi nanti jika ada fitur upload foto profil
      'createdAt': FieldValue.serverTimestamp(),
      // Inisialisasi data statistik
      'savedFoodCount': 0,
      'moneySaved': 0.0,
    });
  }

  /// Mengambil data profil pengguna secara real-time.
  Stream<DocumentSnapshot> getUserProfile() {
    return _db.collection('users').doc(_uid).snapshots();
  }

  // --- FUNGSI MANAJEMEN INVENTARIS ---

  /// Mengambil stream daftar item inventaris milik pengguna saat ini.
  Stream<QuerySnapshot> getInventoryItems() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('items')
        .orderBy('entryDate', descending: true)
        .snapshots();
  }

  /// Fungsi untuk menambahkan item baru ke Firestore dan mengupload gambarnya.
  Future<void> addItem({
    required String itemName,
    required int quantity,
    required String initialCondition,
    required String imagePath,
  }) async {
    final file = File(imagePath);
    final ref = _storage
        .ref()
        .child('item_images')
        .child('${_uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = await ref.putFile(file);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    final itemData = {
      'itemName': itemName,
      'quantity': quantity,
      'initialCondition': initialCondition,
      'imageUrl': imageUrl,
      'entryDate': FieldValue.serverTimestamp(),
      'ownerId': _uid,
    };

    await _db.collection('users').doc(_uid).collection('items').add(itemData);
  }

  /// Menghapus item berdasarkan document ID-nya.
  Future<void> deleteItem(String itemId) async {
    await _db.collection('users').doc(_uid).collection('items').doc(itemId).delete();
  }

  /// Memperbarui data item yang sudah ada.
  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(_uid).collection('items').doc(itemId).update(data);
  }
}