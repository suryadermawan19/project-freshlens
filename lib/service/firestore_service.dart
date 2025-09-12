// lib/service/firestore_service.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:freshlens_ai_app/models/inventory_item_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  User get _currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Pengguna belum login.");
    }
    return user;
  }

  String get _uid => _currentUser.uid;

  // --- FUNGSI PROFIL PENGGUNA ---
  Future<void> createUserProfile({
    required String name,
    required int age,
    required String occupation,
  }) async {
    await _db.collection('users').doc(_uid).set({
      'name': name,
      'age': age,
      'occupation': occupation,
      'email': _currentUser.email,
      'profileImageUrl': null,
      'createdAt': FieldValue.serverTimestamp(),
      'savedFoodCount': 0,
      'moneySaved': 0.0,
      'fcmToken': null,
    });
  }

  Stream<DocumentSnapshot> getUserProfile() {
    return _db.collection('users').doc(_uid).snapshots();
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    await _db.collection('users').doc(_uid).update(data);
  }

  Future<void> uploadProfileImage(String imagePath) async {
    final file = File(imagePath);
    final ref = _storage.ref().child('profile_images').child('$_uid.jpg');
    final uploadTask = await ref.putFile(file);
    final imageUrl = await uploadTask.ref.getDownloadURL();
    await updateUserProfile({'profileImageUrl': imageUrl});
  }

  // --- FUNGSI AKUN & KEAMANAN ---
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final cred = EmailAuthProvider.credential(
      email: _currentUser.email!,
      password: currentPassword,
    );
    await _currentUser.reauthenticateWithCredential(cred);
    await _currentUser.updatePassword(newPassword);
  }

  Future<void> deleteUserAccount() async {
    await _db.collection('users').doc(_uid).delete();
    await _currentUser.delete();
  }

  // --- FUNGSI SENSOR DATA ---
  Stream<DocumentSnapshot> getLatestSensorData() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('sensor_data')
        .doc('latest')
        .snapshots();
  }

  // --- FUNGSI MANAJEMEN EDUKASI ---
  Stream<QuerySnapshot> getArticles() {
    return _db
        .collection('articles')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // --- FUNGSI NOTIFIKASI ---
  /// Menyimpan atau memperbarui FCM token pengguna
  Future<void> saveUserToken(String? token) async {
    if (token == null) return;
    try {
      await _db.collection('users').doc(_uid).update({
        'fcmToken': token,
      });
    } catch (e) {
      if (e is FirebaseException && e.code == 'not-found') {
        // Dokumen user belum ada; biarkan hingga profil dibuat
        // (opsional: bisa disimpan sementara di local prefs)
        // print('Dokumen pengguna belum ada, token akan disimpan saat profil dibuat.');
      } else {
        // print('Gagal menyimpan token: $e');
        rethrow;
      }
    }
  }

  // --- FUNGSI MANAJEMEN INVENTARIS (REVISI) ---

  Stream<QuerySnapshot> getInventoryItems() {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('items')
        .orderBy('entryDate', descending: true)
        .snapshots();
  }

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

  /// [DIUBAH] Mengurangi kuantitas & memperbarui statistik (menggunakan transaksi agar aman).
  /// `Batch` diasumsikan model dengan field `id` dan `quantity`.
  Future<void> markAsUsed(Batch batch, int quantityUsed) async {
    if (quantityUsed <= 0) return;

    final userDocRef = _db.collection('users').doc(_uid);
    final itemDocRef = userDocRef.collection('items').doc(batch.id);
    const double estimatedPricePerItem = 2500.0;

    await _db.runTransaction((transaction) async {
      // Ambil snapshot terkini untuk menghindari kondisi balapan
      final itemSnap = await transaction.get(itemDocRef);
      if (!itemSnap.exists) {
        throw Exception('Batch tidak ditemukan.');
      }

      final currentQty = (itemSnap.data() as Map<String, dynamic>)['quantity'] as int? ?? 0;
      final appliedQty = quantityUsed.clamp(0, currentQty);
      if (appliedQty == 0) {
        // Tidak ada yang bisa dikurangi
        return;
      }

      final newQuantity = currentQty - appliedQty;
      if (newQuantity <= 0) {
        transaction.delete(itemDocRef);
      } else {
        transaction.update(itemDocRef, {'quantity': newQuantity});
      }

      final double moneySaved = appliedQty * estimatedPricePerItem;

      transaction.update(userDocRef, {
        'savedFoodCount': FieldValue.increment(appliedQty),
        'moneySaved': FieldValue.increment(moneySaved),
      });
    });
  }

  /// [DIUBAH] Membuang item (hanya mengurangi kuantitas tanpa update statistik).
  Future<void> discardItems(String batchId, int currentQuantity, int quantityToDiscard) async {
    if (quantityToDiscard <= 0) return;

    final userDocRef = _db.collection('users').doc(_uid);
    final itemDocRef = userDocRef.collection('items').doc(batchId);

    await _db.runTransaction((transaction) async {
      final snap = await transaction.get(itemDocRef);
      if (!snap.exists) return;

      final existingQty = (snap.data() as Map<String, dynamic>)['quantity'] as int? ?? 0;
      final appliedQty = quantityToDiscard.clamp(0, existingQty);
      final newQuantity = existingQty - appliedQty;

      if (newQuantity <= 0) {
        transaction.delete(itemDocRef);
      } else {
        transaction.update(itemDocRef, {'quantity': newQuantity});
      }
    });
  }

  /// [DIUBAH] Men-set kuantitas baru; jika <= 0, item dihapus.
  Future<void> updateItemQuantity(String batchId, int newQuantity) async {
    final itemDocRef = _db.collection('users').doc(_uid).collection('items').doc(batchId);
    if (newQuantity <= 0) {
      await itemDocRef.delete();
    } else {
      await itemDocRef.update({'quantity': newQuantity});
    }
  }

  // Catatan: deleteItem lama digantikan oleh discardItems / updateItemQuantity.
}
