import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models_exports.dart';
import '../repositories/repositories_exports.dart';
import '../services/onesignal_service.dart';
import '../services/offline_map_storage_service.dart';
import '../core/utils/app_logger.dart';

enum AuthState {
  unauthenticated,
  authenticating,
  authenticatedWithRole,
  error,
}

class UserProvider extends ChangeNotifier {
  UserProvider(this._authRepo);

  final AuthRepository _authRepo;

  AppUser? _currentUser;
  UserRole _currentRole = UserRole.VARKARI;
  AuthState _authState = AuthState.unauthenticated;
  bool _isDemoMode = false;
  String? _errorMessage;
  String _currentLanguage = 'en';

  AppUser? get currentUser => _currentUser;
  UserRole get currentRole => _currentRole;
  AuthState get authState => _authState;
  bool get isAuthenticated => _authState == AuthState.authenticatedWithRole && _currentUser != null;
  bool get isDemoMode => _isDemoMode;
  String? get errorMessage => _errorMessage;
  String get currentLanguage => _currentLanguage;
  bool get isVolunteerEnabled => _currentUser?.volunteerEnabled ?? false;
  bool get isVolunteerApproved => _currentUser?.isVolunteerApproved ?? false;
  bool get isDindiLeaderApproved => _currentUser?.isDindiLeaderApproved ?? false;
  bool get isSanitationApproved => _currentUser?.isSanitationApproved ?? false;

  String get volunteerStatus => _currentUser?.volunteerStatus ?? 'NONE';
  String get dindiLeaderStatus => _currentUser?.dindiLeaderStatus ?? 'NONE';
  String get sanitationStatus => _currentUser?.sanitationStatus ?? 'NONE';

  /// Helper for unit tests / default initialization.
  void initDefaultSession() {
    _authState = AuthState.unauthenticated;
    _currentUser = null;
    notifyListeners();
  }

  /// Load saved persistent user session & role on app launch or restart.
  Future<void> loadSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('auth_user_json');
      final roleStr = prefs.getString('auth_role_name');
      final isAuth = prefs.getBool('auth_is_authenticated') ?? false;

      if (isAuth && userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> map = jsonDecode(userJsonStr);
        final user = AppUser.fromJson(map);
        _currentUser = user;
        if (roleStr != null && roleStr.isNotEmpty) {
          _currentRole = UserRoleX.fromString(roleStr);
        } else {
          _currentRole = user.userRole;
        }
        _isDemoMode = user.isDemoMode;
        _authState = AuthState.authenticatedWithRole;
        OneSignalService().loginUser(user.userId);
        AppLogger.i('Restored persistent user session for ${user.displayName} as ${_currentRole.displayName}');
        notifyListeners();
        return;
      }
    } catch (e) {
      AppLogger.w('Failed to restore saved user session: $e');
    }
    initDefaultDemoUser();
  }

  /// Save active user session & role to SharedPreferences for automatic login on restart.
  Future<void> _persistSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUser != null && _authState == AuthState.authenticatedWithRole) {
        await prefs.setString('auth_user_json', jsonEncode(_currentUser!.toJson()));
        await prefs.setString('auth_role_name', _currentRole.name);
        await prefs.setBool('auth_is_authenticated', true);
      } else {
        await prefs.remove('auth_user_json');
        await prefs.remove('auth_role_name');
        await prefs.setBool('auth_is_authenticated', false);
      }
    } catch (e) {
      AppLogger.w('Session persistence warning: $e');
    }
  }

  /// Helper for unit tests / demo user testing.
  void initDefaultDemoUser() {
    _currentUser = const AppUser(
      userId: 'usr-demo-1',
      email: 'varkari.demo@wariverse.ai',
      role: 'VARKARI',
      displayName: 'Demonstration Pilgrim',
      isDemoMode: true,
    );
    _currentRole = UserRole.VARKARI;
    _authState = AuthState.authenticatedWithRole;
    _isDemoMode = true;
    _persistSession();
    notifyListeners();
  }

  /// Toggle volunteer willingness capability for the current Varkari user.
  Future<bool> setVolunteerWillingness(bool enabled) async {
    if (_currentUser == null) return false;

    try {
      await _authRepo.updateVolunteerWillingness(_currentUser!.userId, enabled);
      _currentUser = _currentUser!.copyWith(
        volunteerEnabled: enabled,
        volunteerStatus: enabled ? 'APPROVED' : 'NONE',
        volunteerAvailable: enabled,
      );
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Request a secondary capability (volunteer, dindi_leader, sanitation).
  Future<bool> requestCapability(String capability) async {
    if (_currentUser == null) return false;

    try {
      await _authRepo.requestCapability(_currentUser!.userId, capability);
      if (capability == 'volunteer') {
        _currentUser = _currentUser!.copyWith(volunteerStatus: 'REQUESTED');
      } else if (capability == 'dindi_leader') {
        _currentUser = _currentUser!.copyWith(dindiLeaderStatus: 'REQUESTED');
      } else if (capability == 'sanitation') {
        _currentUser = _currentUser!.copyWith(sanitationStatus: 'REQUESTED');
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Admin sets status for user capabilities.
  Future<bool> adminSetCapabilityStatus(String targetUid, String capability, String newStatus) async {
    if (_currentUser == null) return false;

    try {
      await _authRepo.adminSetCapabilityStatus(_currentUser!.userId, targetUid, capability, newStatus);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Switch active role and persist to local storage.
  void switchRole(UserRole role) {
    _currentRole = role;
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(role: role.name);
    }
    _persistSession();
    notifyListeners();
  }

  /// Promote current user to Dindi Leader upon Virtual Dindi creation.
  void promoteToDindiLeader() {
    _currentRole = UserRole.DINDI_LEADER;
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        role: 'DINDI_LEADER',
        dindiLeaderStatus: 'APPROVED',
      );
    }
    _persistSession();
    notifyListeners();
  }

  /// Update user profile details in state, local session, and Firestore.
  void updateProfileInfo({required String displayName, String? phone}) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        displayName: displayName,
      );
      _persistSession();
      try {
        final fs = _authRepo.firestore;
        if (fs != null) {
          fs.collection('users').doc(_currentUser!.userId).set({
            'displayName': displayName,
            if (phone != null && phone.isNotEmpty) 'phone': phone,
            'updated_at': DateTime.now().toIso8601String(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}
      notifyListeners();
    }
  }

  void setRole(UserRole role) => switchRole(role);

  /// Sets authenticated user session derived strictly from backend/Firestore authoritative authentication.
  void setAuthenticatedUser(AppUser user) {
    _currentUser = user;
    _currentRole = user.userRole;
    _isDemoMode = user.isDemoMode;
    _authState = AuthState.authenticatedWithRole;
    OneSignalService().loginUser(user.userId);
    _persistSession();
    notifyListeners();
  }

  /// Log in with email, password, and portal role validation.
  Future<bool> login(String email, String password, {String? requestedPortalRole}) async {
    _authState = AuthState.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.login(email, password, requestedPortalRole: requestedPortalRole);
      setAuthenticatedUser(result.user);
      return true;
    } catch (e) {
      _authState = AuthState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Register new user with specific role and profile attributes.
  Future<bool> register({
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
    _authState = AuthState.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await _authRepo.register(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
        phone: phone,
        age: age,
        gender: gender,
        bloodGroup: bloodGroup,
        dindiCode: dindiCode,
      );
      setAuthenticatedUser(user);
      return true;
    } catch (e) {
      _authState = AuthState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Send password reset email via Firebase Auth.
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _authRepo.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  /// Complete production logout.
  void logout() async {
    OneSignalService().logoutUser();
    OfflineMapStorageService().clearUserPrivateOfflineData();
    _authRepo.signOut();
    _currentUser = null;
    _currentRole = UserRole.VARKARI;
    _authState = AuthState.unauthenticated;
    _isDemoMode = false;
    _errorMessage = null;
    _authRepo.clearToken();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_user_json');
      await prefs.remove('auth_role_name');
      await prefs.setBool('auth_is_authenticated', false);
    } catch (_) {}
    notifyListeners();
  }

  /// Set app language (en, mr, hi).
  void setLanguage(String lang) {
    if (_currentLanguage != lang) {
      _currentLanguage = lang;
      notifyListeners();
    }
  }
}
