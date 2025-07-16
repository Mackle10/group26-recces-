// O11 import 'package:firebase_storage/firebase_storage.dart';
 
// O11 abstract class StorageDataSource {
// O11   Future<String> uploadImage(String path, String filePath);
// O11   Future<void> deleteImage(String url);
// O11 }
 
// O11 class FirebaseStorageDataSource implements StorageDataSource {
// O11   final FirebaseStorage _storage = FirebaseStorage.instance;
 
// O11   @override
// O11   Future<String> uploadImage(String path, String filePath) async {
// O11     final ref = _storage.ref().child(path);
// O11     await ref.putFile(File(filePath));
// O11     return await ref.getDownloadURL();
// O11   }
 
// O11   @override
// O11   Future<void> deleteImage(String url) async {
// O11     final ref = _storage.refFromURL(url);
// O11     await ref.delete();
// O11   }
// O11 }