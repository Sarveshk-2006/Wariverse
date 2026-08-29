import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../models/models_exports.dart';
import '../core/utils/app_logger.dart';

/// Result type that carries auth data and its origin.
class AuthResult {
  final AppUser user;
  final bool isDemoMode;
  const AuthResult(this.user, {this.isDemoMode = false});
}

/// Repository for authoritative Firebase Authentication and Firestore profile management.
class AuthRepository {
  AuthRepository(
    this._api, {
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  final ApiService _api;
  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  FirebaseAuth get auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get db => _firestore ?? FirebaseFirestore.instance;

  /// Map Firebase Auth Exception codes to user-friendly error messages.
  static String mapAuthExceptionMessage(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'invalid-login-credentials':
          return 'Invalid email or password.';
        case 'user-not-found':
          return 'No account exists with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'network-request-failed':
          return 'Network connection failed. Please check your internet connection.';
        case 'operation-not-allowed':
          return 'Email/password sign-in is not enabled in Firebase Console.';
        case 'email-already-in-use':
          return 'An account with this email address already exists.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        default:
          return e.message ?? 'Authentication failed. (Code: ${e.code})';
      }
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  /// Authentic Firebase Authentication login with email, password, and portal authorization check.
  Future<AuthResult> login(String email, String password, {String? requestedPortalRole}) async {
    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication returned null user identity.');
      }

      final uid = firebaseUser.uid;
      AppLogger.i('Firebase Auth login successful for UID: $uid');

      String role = 'VARKARI';
      String displayName = firebaseUser.displayName ?? email.split('@').first;

      try {
        final userDoc = await db.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          role = data['role'] as String? ?? 'VARKARI';
          displayName = data['display_name'] as String? ?? displayName;
        } else {
          // Auto-create initial user record in Firestore if missing
          await db.collection('users').doc(uid).set({
            'uid': uid,
            'email': email.trim(),
            'display_name': displayName,
            'role': 'VARKARI',
            'created_at': DateTime.now().toIso8601String(),
          });
        }

        final profileDoc = await db.collection('profiles').doc(uid).get();
        if (!profileDoc.exists) {
          await db.collection('profiles').doc(uid).set({
            'uid': uid,
            'full_name': displayName,
            'role': role,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      } catch (firestoreErr) {
        AppLogger.i('Firestore profile read warning for UID $uid: $firestoreErr');
      }

      // Check role authorization if a specific portal role was requested
      if (requestedPortalRole != null && requestedPortalRole.isNotEmpty && requestedPortalRole != 'ALL') {
        final normReq = requestedPortalRole.toUpperCase();
        final normActual = role.toUpperCase();

        if (normReq != normActual && normActual != 'ADMIN') {
          throw Exception('You are not authorized for the $requestedPortalRole Portal. Your registered role is $role.');
        }
      }

      final user = AppUser(
        userId: uid,
        email: email.trim(),
        role: role,
        displayName: displayName,
        isDemoMode: false,
      );

      return AuthResult(user, isDemoMode: false);
    } catch (e) {
      final userMsg = mapAuthExceptionMessage(e);
      throw Exception(userMsg);
    }
  }

  /// Register new user account using Firebase Authentication.
  Future<AppUser> register({
    required String email,
    required String password,
    required String displayName,
    String role = 'VARKARI',
    String? phone,
    int? age,
    String? gender,
    String? bloodGroup,
    String? dindiCode,
  }) async {
    final requestedRole = role.toUpperCase();
    if (['ADMIN', 'POLICE', 'MEDICAL_TEAM', 'CLEANER'].contains(requestedRole)) {
      throw Exception('Privileged operational roles ($requestedRole) require Admin authorization and cannot be self-registered.');
    }

    try {
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase registration returned null user identity.');
      }

      final uid = firebaseUser.uid;
      await firebaseUser.updateDisplayName(displayName);

      final userData = <String, dynamic>{
        'uid': uid,
        'email': email.trim(),
        'display_name': displayName,
        'role': requestedRole,
        'is_active': true,
        'is_verified': requestedRole == 'VARKARI',
        'created_at': DateTime.now().toIso8601String(),
      };
      if (phone != null && phone.isNotEmpty) userData['phone'] = phone;
      if (dindiCode != null && dindiCode.isNotEmpty) userData['dindi_id'] = dindiCode;

      await db.collection('users').doc(uid).set(userData);

      // Create profiles/{uid} in Firestore
      await db.collection('profiles').doc(uid).set({
        'uid': uid,
        'full_name': displayName,
        'email': email.trim(),
        'phone': phone ?? '',
        'age': age ?? 0,
        'gender': gender ?? 'Not Specified',
        'blood_group': bloodGroup ?? 'O+',
        'role': requestedRole,
        'created_at': DateTime.now().toIso8601String(),
      });

      return AppUser(
        userId: uid,
        email: email.trim(),
        role: requestedRole,
        displayName: displayName,
        isDemoMode: false,
      );
    } catch (e) {
      final userMsg = mapAuthExceptionMessage(e);
      throw Exception(userMsg);
    }
  }

  /// Trigger Firebase Authentication Password Reset Email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      throw Exception(mapAuthExceptionMessage(e));
    }
  }

  /// Sign out current Firebase Auth user.
  Future<void> signOut() async {
    try {
      await auth.signOut();
    } catch (_) {}
  }

  void setToken(String token) => _api.setToken(token);
  void clearToken() => _api.setToken(null);
}
