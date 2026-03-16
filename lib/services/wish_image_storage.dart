import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

const String _bucketPath = 'wish_images';

/// Загружает файл изображения в Storage и возвращает URL для сохранения в пожелании.
Future<String?> uploadWishImage(File file) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return null;
  final ref = FirebaseStorage.instance
      .ref()
      .child(_bucketPath)
      .child(uid)
      .child('${DateTime.now().millisecondsSinceEpoch}_${file.path.split(Platform.pathSeparator).last}');
  await ref.putFile(file);
  return ref.getDownloadURL();
}
