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
      final formattedId = studentId.trim().toUpperCase();
      final email = "$formattedId@unibus.app";

      // 1 Check if Student ID exists in students collection
      final studentDoc = await _firestore
          .collection('students')
          .doc(formattedId)
          .get();

      if (!studentDoc.exists) {
        throw Exception('Invalid Student ID');
      }

      final studentData = studentDoc.data()!;

      // 2 Prevent duplicate registration
      final existingUser = await _firestore
          .collection('users')
          .where('studentId', isEqualTo: formattedId)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Account already exists');
      }

      // 3 Create Firebase Auth account
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 4 Copy student data into users collection
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'studentId': formattedId,
        'name': studentData['name'] ?? "",
        'batch': studentData['batch'] ?? "",
        'year': studentData['year'] ?? "",
        'cardStatus': studentData['cardStatus'] ?? "inactive",
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e));
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
      final formattedId = studentId.trim().toUpperCase();
      final email = "$formattedId@unibus.app";

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
