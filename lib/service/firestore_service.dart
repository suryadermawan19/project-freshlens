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
      'fcmToken': null, // Tambahkan field fcmToken saat profil dibuat
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
    return _db.collection('users').doc(_uid).collection('sensor_data').doc('latest').snapshots();
  }

  // --- FUNGSI MANAJEMEN INVENTARIS ---
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
  
  Future<void> markAsUsed(Batch batch) async {
    final userDocRef = _db.collection('users').doc(_uid);
    final itemDocRef = _db.collection('users').doc(_uid).collection('items').doc(batch.id);
    const double estimatedPricePerItem = 2500.0;
    final double moneySaved = batch.quantity * estimatedPricePerItem;

    return _db.runTransaction((transaction) async {
      transaction.update(userDocRef, {
        'savedFoodCount': FieldValue.increment(batch.quantity),
        'moneySaved': FieldValue.increment(moneySaved),
      });
      transaction.delete(itemDocRef);
    });
  }

  Future<void> deleteItem(String itemId) async {
    await _db.collection('users').doc(_uid).collection('items').doc(itemId).delete();
  }

  Future<void> updateItem(String itemId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(_uid).collection('items').doc(itemId).update(data);
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
      // Handle error jika diperlukan, misalnya jika pengguna belum melengkapi profil
      // dan dokumennya belum ada.
      if (e is FirebaseException && e.code == 'not-found') {
        print('Dokumen pengguna belum ada, token akan disimpan saat profil dibuat.');
      } else {
        print('Gagal menyimpan token: $e');
      }
    }
  }

  // --- FUNGSI MANAJEMEN EDUKASI ---
  Stream<QuerySnapshot> getArticles() {
    return _db
        .collection('articles')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}