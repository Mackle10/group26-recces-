// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:io';

// abstract class StorageDataSource {
//   Future<String> uploadImage(String path, String filePath);
//   Future<void> deleteImage(String url);
// }

// class FirebaseStorageDataSource implements StorageDataSource {
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   @override
// // O11   Future<String> uploadImage(String path, String filePath) async {
//     final ref = _storage.ref().child(path);
//     await ref.putFile(File(filePath));
//     return await ref.getDownloadURL();
//   }

//   @override
//   Future<void> deleteImage(String url) async {
//   final ref = _storage.refFromURL(url);
//     await ref.delete();
//   }
// }