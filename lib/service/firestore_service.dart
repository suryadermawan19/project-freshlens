import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirestoreService {
  // DEKLARASIKAN SEBAGAI MEMBER KELAS AGAR DIKENALI SEMUA FUNGSI
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser!.uid;

  Stream<Map<String, dynamic>?> latestReading(String podId) {
    return _db.collection('pods').doc(podId).collection('readings')
      .orderBy('created_at', descending: true).limit(1)
      .snapshots()
      .map((s) => s.docs.isEmpty ? null : s.docs.first.data());
  }

  Stream<List<Map<String, dynamic>>> urgentItems() {
    return _db.collection('users').doc(uid).collection('items')
      .where('status', isNotEqualTo: 'HIJAU')
      .orderBy('status') 
      .limit(10)
      .snapshots()
      .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Fungsi untuk menambahkan item baru ke Firestore dan mengupload gambarnya.
  Future<void> addItem({
    required String itemName,
    required int quantity,
    required String initialCondition,
    required String imagePath,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("Pengguna belum login.");
    }

    // 1. Upload gambar ke Firebase Storage
    final file = File(imagePath);
    final ref = FirebaseStorage.instance
        .ref()
        .child('item_images')
        .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

    final uploadTask = await ref.putFile(file);
    final imageUrl = await uploadTask.ref.getDownloadURL();

    // 2. Siapkan data untuk disimpan ke Firestore
    final itemData = {
      'itemName': itemName,
      'quantity': quantity,
      'initialCondition': initialCondition,
      'imageUrl': imageUrl,
      'entryDate': FieldValue.serverTimestamp(),
      'ownerId': user.uid,
    };

    // 3. Simpan data ke sub-collection 'items' milik pengguna
    await _db.collection('users').doc(user.uid).collection('items').add(itemData);
  }
}