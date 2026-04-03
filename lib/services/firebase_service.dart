import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Single interface to all Firebase operations.
/// No other file should import firebase_auth or cloud_firestore directly.
class FirebaseService {
  FirebaseService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Init ───────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    await Firebase.initializeApp();
  }

  // ─── Auth state ─────────────────────────────────────────────────────────────

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => _auth.currentUser != null;
  static String? get uid => _auth.currentUser?.uid;

  // ─── Sign-up ────────────────────────────────────────────────────────────────

  /// Creates a new Firebase Auth user with email + password.
  static Future<UserCredential> signUp(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─── Sign-in ────────────────────────────────────────────────────────────────

  /// Signs in an existing user with email + password.
  static Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─── Sign-out ───────────────────────────────────────────────────────────────

  static Future<void> signOut() => _auth.signOut();

  // ─── Firestore ──────────────────────────────────────────────────────────────

  static DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Creates user document only when it does not already exist.
  static Future<void> createUserDocumentIfAbsent(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final doc = await _userDoc(uid).get();
    if (!doc.exists) {
      await _userDoc(uid).set(data);
    }
  }

  /// Fetches the user document. Returns null if the document does not exist.
  static Future<Map<String, dynamic>?> fetchUserDocument(String uid) async {
    final doc = await _userDoc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// Partially updates the user document (merge = true so it never overwrites).
  static Future<void> updateUserDocument(
    String uid,
    Map<String, dynamic> data,
  ) {
    return _userDoc(uid).set(data, SetOptions(merge: true));
  }

  // ─── Error helper ───────────────────────────────────────────────────────────

  /// Converts a [FirebaseAuthException] code into a human-readable message.
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found. Switch to Register.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password. Try again.';
      case 'email-already-in-use':
        return 'Email already registered. Login instead.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No connection. Check your internet.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
