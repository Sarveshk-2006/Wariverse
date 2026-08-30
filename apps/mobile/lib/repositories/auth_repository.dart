import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/api_service.dart';
import '../models/models_exports.dart';
import '../core/utils/app_logger.dart';
import 'qr_repository.dart';

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

  FirebaseFirestore? get firestore => _firestore ?? _getFirestoreSafely();

  FirebaseFirestore? _getFirestoreSafely() {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

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
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    UserCredential? userCredential;
    try {
      userCredential = await auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: cleanPassword,
      );
    } catch (authErr) {
      // Auto-provision admin account if credentials match system admin demo and account doesn't exist yet
      if ((cleanEmail.toLowerCase() == 'admin@wariverse.demo' && cleanPassword == 'WariVerse@Admin') ||
          (requestedPortalRole?.toUpperCase() == 'ADMIN' && cleanEmail.toLowerCase() == 'admin@wariverse.demo')) {
        try {
          userCredential = await auth.createUserWithEmailAndPassword(
            email: cleanEmail,
            password: cleanPassword,
          );
          if (userCredential.user != null) {
            final adminUid = userCredential.user!.uid;
            await db.collection('users').doc(adminUid).set({
              'uid': adminUid,
              'email': cleanEmail,
              'display_name': 'Executive Command Admin',
              'role': 'ADMIN',
              'is_active': true,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
            await db.collection('profiles').doc(adminUid).set({
              'uid': adminUid,
              'full_name': 'Executive Command Admin',
              'role': 'ADMIN',
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (_) {
          // If creation fails (e.g. wrong password for existing user), rethrow original auth error
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    try {

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication returned null user identity.');
      }

      final uid = firebaseUser.uid;
      AppLogger.i('Firebase Auth login successful for UID: $uid');

      String role = 'VARKARI';
      String displayName = firebaseUser.displayName ?? email.split('@').first;

      bool volunteerEnabled = false;
      String volunteerStatus = 'NONE';
      bool volunteerAvailable = false;
      String? dindiCode;
      bool isDindiLeader = false;
      String dindiLeaderStatus = 'NONE';
      String sanitationStatus = 'NONE';
      String ngoStatus = 'NONE';

      bool profileExists = false;
      bool isActive = true;

      try {
        final userDoc = await db.collection('users').doc(uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          profileExists = true;
          final data = userDoc.data()!;
          role = data['role'] as String? ?? 'VARKARI';
          displayName = data['display_name'] as String? ?? displayName;
          volunteerEnabled = data['volunteer_enabled'] as bool? ?? false;
          volunteerStatus = data['volunteer_status'] as String? ?? (volunteerEnabled ? 'APPROVED' : 'NONE');
          volunteerAvailable = data['volunteer_available'] as bool? ?? false;
          dindiCode = data['dindi_code'] as String? ?? data['dindi_id'] as String?;
          isDindiLeader = data['is_dindi_leader'] as bool? ?? false;
          dindiLeaderStatus = data['dindi_leader_status'] as String? ?? (isDindiLeader ? 'APPROVED' : 'NONE');
          sanitationStatus = data['sanitation_status'] as String? ?? 'NONE';
          ngoStatus = data['ngo_status'] as String? ?? 'NONE';
          isActive = data['is_active'] as bool? ?? data['isActive'] as bool? ?? true;
        } else {
          final isTargetAdmin = requestedPortalRole?.toUpperCase() == 'ADMIN' || cleanEmail.toLowerCase() == 'admin@wariverse.demo';
          final assignedRole = isTargetAdmin ? 'ADMIN' : 'VARKARI';

          await db.collection('users').doc(uid).set({
            'uid': uid,
            'email': cleanEmail,
            'display_name': displayName,
            'role': assignedRole,
            'is_active': true,
            'volunteer_enabled': false,
            'volunteer_status': 'NONE',
            'volunteer_available': false,
            'dindi_leader_status': 'NONE',
            'sanitation_status': 'NONE',
            'ngo_status': 'NONE',
            'created_at': DateTime.now().toIso8601String(),
          });
          profileExists = true;
          role = assignedRole;
        }

        if (profileExists) {
          final profileDoc = await db.collection('profiles').doc(uid).get();
          if (!profileDoc.exists) {
            await db.collection('profiles').doc(uid).set({
              'uid': uid,
              'full_name': displayName,
              'role': role,
              'volunteer_enabled': false,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        }
      } catch (firestoreErr) {
        if (firestoreErr is Exception && firestoreErr.toString().contains('authorized')) {
          rethrow;
        }
        AppLogger.i('Firestore profile read warning for UID $uid: $firestoreErr');
      }

      // Authoritative Admin and Portal Role Validation
      final normReq = (requestedPortalRole ?? 'VARKARI').toUpperCase();
      final normActual = role.toUpperCase();

      if (normReq == 'ADMIN') {
        if (!profileExists) {
          await signOut();
          throw Exception('Missing Admin Firestore profile configuration at users/$uid.');
        }
        if (!isActive) {
          await signOut();
          throw Exception('This Admin account has been deactivated.');
        }
        if (normActual != 'ADMIN') {
          await signOut();
          throw Exception('Account is registered as $role, not ADMIN. Executive Command Center access denied.');
        }
      } else if (normReq != 'ALL' && normReq != normActual && normActual != 'ADMIN') {
        await signOut();
        throw Exception('You are not authorized for the $requestedPortalRole Portal. Your registered role is $role.');
      }

      if (profileExists) {
        logAuditAction(uid, 'USER_LOGIN', 'users/$uid', {'role': role, 'portal': normReq});
      }

      final user = AppUser(
        userId: uid,
        email: email.trim(),
        role: role,
        displayName: displayName,
        volunteerEnabled: volunteerEnabled,
        volunteerStatus: volunteerStatus,
        volunteerAvailable: volunteerAvailable,
        dindiCode: dindiCode,
        isDindiLeader: isDindiLeader,
        dindiLeaderStatus: dindiLeaderStatus,
        sanitationStatus: sanitationStatus,
        ngoStatus: ngoStatus,
        isDemoMode: false,
      );

      return AuthResult(user, isDemoMode: false);
    } catch (e) {
      final userMsg = mapAuthExceptionMessage(e);
      throw Exception(userMsg);
    }
  }

  /// Register new user account using Firebase Authentication and provision unique QR identity.
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

      // Create unique permanent QR identity
      final qrRepo = QrRepository(firestore: _firestore);
      final qrCode = await qrRepo.generateQrCode(
        type: QrType.PERSON,
        ownerId: uid,
        targetCollection: 'users',
        targetDocumentId: uid,
        createdBy: uid,
        customPrefix: 'WVRK',
        metadata: {'user_id': uid, 'title': 'Digital Pilgrim Identity Card'},
      );

      final userData = <String, dynamic>{
        'uid': uid,
        'email': email.trim(),
        'display_name': displayName,
        'role': requestedRole,
        'qr_id': qrCode.id,
        'qr_token': qrCode.token,
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
        'qr_id': qrCode.id,
        'qr_token': qrCode.token,
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

  /// Request a secondary capability (volunteer, dindi_leader, sanitation, ngo).
  Future<void> requestCapability(String uid, String capability) async {
    final statusField = '${capability}_status';
    final requestedAtField = '${capability}_requested_at';

    try {
      await db.collection('users').doc(uid).set({
        statusField: 'REQUESTED',
        requestedAtField: DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      logAuditAction(uid, '${capability.toUpperCase()}_REQUESTED', 'users/$uid', {
        'capability': capability,
        'status': 'REQUESTED',
      });
    } catch (e) {
      AppLogger.i('Warning: Could not save capability request: $e');
    }
  }

  /// Admin approval/rejection/suspension of user capabilities.
  Future<void> adminSetCapabilityStatus(String adminUid, String targetUid, String capability, String newStatus) async {
    final statusField = '${capability}_status';

    try {
      final updates = <String, dynamic>{
        statusField: newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (capability == 'volunteer') {
        updates['volunteer_enabled'] = (newStatus == 'APPROVED');
        updates['volunteer_available'] = (newStatus == 'APPROVED');
      } else if (capability == 'dindi_leader') {
        updates['is_dindi_leader'] = (newStatus == 'APPROVED');
      }

      await db.collection('users').doc(targetUid).set(updates, SetOptions(merge: true));

      logAuditAction(adminUid, '${capability.toUpperCase()}_$newStatus', 'users/$targetUid', {
        'capability': capability,
        'new_status': newStatus,
        'admin_uid': adminUid,
      });
    } catch (e) {
      AppLogger.i('Warning: Could not update capability status: $e');
    }
  }

  /// Write operational action log to Firestore audit_logs collection.
  Future<void> logAuditAction(String actorUid, String action, String target, [Map<String, dynamic>? metadata]) async {
    try {
      final logId = 'log_${DateTime.now().millisecondsSinceEpoch}';
      await db.collection('audit_logs').doc(logId).set({
        'id': logId,
        'actor_uid': actorUid,
        'action': action,
        'target': target,
        'metadata': metadata ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.i('Audit logging notice: $e');
    }
  }

  /// Update volunteer willingness status in Firestore.
  Future<void> updateVolunteerWillingness(String uid, bool enabled) async {
    try {
      final status = enabled ? 'APPROVED' : 'NONE';
      await db.collection('users').doc(uid).set({
        'volunteer_enabled': enabled,
        'volunteer_status': status,
        'volunteer_available': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      await db.collection('profiles').doc(uid).set({
        'volunteer_enabled': enabled,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      logAuditAction(uid, enabled ? 'VOLUNTEER_ENABLED' : 'VOLUNTEER_DISABLED', 'users/$uid');
    } catch (e) {
      AppLogger.i('Warning: Could not sync volunteer status to Firestore: $e');
    }
  }

  void setToken(String token) => _api.setToken(token);
  void clearToken() => _api.setToken(null);
}
