import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Convert username to fake email for Firebase Auth
  String _toEmail(String username) => '$username@trolleymate.app';

  // Current user
  User? get currentUser => _auth.currentUser;

  // ===== SIGN UP =====
  Future<String?> signUp({
    required String fullName,
    required String username,
    required String password,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: _toEmail(username),
        password: password,
      );

      final uid = credential.user!.uid;

      // Save additional user data in Firestore
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': fullName,
        'username': username,
        'role': 'customer',
        'securityQuestion': securityQuestion,
        'securityAnswer': securityAnswer,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // success
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Signup failed';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ===== LOGIN =====
  Future<String?> login({
    required String username,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _toEmail(username),
        password: password,
      );
      return null; // success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        return 'Invalid username or password';
      }
      return e.message ?? 'Login failed';
    } catch (e) {
      return 'Error: $e';
    }
  }

  // ===== LOGOUT =====
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ===== GET USER PROFILE FROM FIRESTORE =====
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // ===== GET SECURITY QUESTION BY USERNAME =====
  Future<Map<String, String>?> getSecurityQuestion(String username) async {
    try {
      final query = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;

      final data = query.docs.first.data();
      return {
        'question': data['securityQuestion'] ?? '',
        'answer': data['securityAnswer'] ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  // ===== UPDATE USER NAME =====
  Future<void> updateName(String newName) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({'name': newName});
  }
}