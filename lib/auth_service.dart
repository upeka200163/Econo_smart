import 'dart:io';
import 'dart:developer' as dev;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> registerUser({
    required String username,
    required String email,
    required String password,
    File? profileImage,
  }) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = cred.user!.uid;
      String? imageUrl;

      if (profileImage != null) {
        final ref = _storage.ref().child('profile_images/$uid.jpg');
        await ref.putFile(profileImage);
        imageUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'username': username,
        'email': email,
        'profileImageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'totalBalance': 0.0,
        'income': 0.0,
        'expenses': 0.0,
      });

      return null;
    } on FirebaseAuthException catch (e) {
      dev.log("Auth Error: [${e.code}] ${e.message}");
      return e.message;
    } catch (e) {
      dev.log("General Error: $e");
      return e.toString();
    }
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      dev.log("Login Error: ${e.code} - ${e.message}");
      return e.message;
    }
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> updateUsername(String username) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'User not signed in.';
      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.update({'username': username});
      return null;
    } catch (e) {
      dev.log('Update username error: $e');
      return e.toString();
    }
  }

  Future<String?> updatePassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'User not signed in.';
      await user.updatePassword(password);
      return null;
    } on FirebaseAuthException catch (e) {
      dev.log('Password update error: ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      dev.log('Password update error: $e');
      return e.toString();
    }
  }

  Future<String?> updateProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'User not signed in.';

      final ref = _storage.ref().child('profile_images/${user.uid}.jpg');
      await ref.putFile(imageFile);
      final imageUrl = await ref.getDownloadURL();

      final userDoc = _firestore.collection('users').doc(user.uid);
      await userDoc.update({'profileImageUrl': imageUrl});

      return null;
    } on FirebaseException catch (e) {
      dev.log('Profile image update error: ${e.code} - ${e.message}');
      return e.message;
    } catch (e) {
      dev.log('Profile image update error: $e');
      return e.toString();
    }
  }

  User? get currentUser => _auth.currentUser;
}
