import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// REGISTER
  static Future<void> register({
    required String studentId,
    required String password,
  }) async {
    // 1. Check student exists
    final studentDoc = await _firestore
        .collection('students')
        .doc(studentId)
        .get();

    if (!studentDoc.exists) {
      throw Exception('Invalid Student ID');
    }

    // 2. Prevent duplicate registration
    final existingUser = await _firestore
        .collection('users')
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();

    if (existingUser.docs.isNotEmpty) {
      throw Exception('Account already exists');
    }

    // 3. Create Firebase Auth account
    final email = '$studentId@unibus.app';

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // 4. Create user profile
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'studentId': studentId,
      'role': 'student',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// LOGIN
  static Future<void> login({
    required String studentId,
    required String password,
  }) async {
    final email = '$studentId@unibus.app';

    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// LOGOUT
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// CHANGE PASSWORD
  static Future<void> changePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Not logged in');
    }
    await user.updatePassword(newPassword);
  }

  /// CURRENT USER UID
  static String? get currentUid => _auth.currentUser?.uid;
}
