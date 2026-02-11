import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// =========================
  /// REGISTER
  /// =========================
  static Future<void> register({
    required String studentId,
    required String password,
    

  }) async {
    try {
      // 1️⃣ Check if Student ID exists in students collection
      final studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();

      if (!studentDoc.exists) {
        throw Exception('Invalid Student ID');
      }

      // 2️⃣ Prevent duplicate registration
      final existingUser = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: studentId)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Account already exists');
      }

      // 3️⃣ Create Firebase Auth account
      final email = "$studentId@unibus.app";

      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 4️⃣ Create user profile in Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'studentId': studentId,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

    } on FirebaseAuthException catch (e) {
  print("ERROR CODE: ${e.code}");
  print("ERROR MESSAGE: ${e.message}");
  throw Exception(e.code);
}

  }

  /// =========================
  /// LOGIN
  /// =========================
  static Future<void> login({
    required String studentId,
    required String password,
  }) async {
    try {
      final email = "${studentId.toLowerCase()}@unibus.app";


      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
    }
  }

  /// =========================
  /// LOGOUT
  /// =========================
  static Future<void> logout() async {
    await _auth.signOut();
  }

  /// =========================
  /// CHANGE PASSWORD
  /// =========================
  static Future<void> changePassword(
      String newPassword) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User not logged in');
    }

    await user.updatePassword(newPassword);
  }

  /// =========================
  /// CURRENT USER
  /// =========================
  static User? get currentUser => _auth.currentUser;

  /// =========================
  /// ERROR HANDLER
  /// =========================
  static String _handleAuthError(
      FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Account already exists';
      case 'invalid-email':
        return 'Invalid Student ID';
      case 'weak-password':
        return 'Password is too weak';
      case 'user-not-found':
        return 'Student not registered';
      case 'wrong-password':
        return 'Incorrect password';
      default:
        return 'Authentication error. Try again.';
    }
  }
}
