import 'package:flutter/material.dart';
import '../models/models_exports.dart';
import '../repositories/repositories_exports.dart';
import '../services/onesignal_service.dart';

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

  /// Helper for unit tests / default initialization.
  void initDefaultSession() {
    _authState = AuthState.unauthenticated;
    _currentUser = null;
    notifyListeners();
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
    notifyListeners();
  }

  /// Switch active role for authorized administrative testing.
  void switchRole(UserRole role) {
    _currentRole = role;
    notifyListeners();
  }

  /// Sets authenticated user session derived strictly from backend/Firestore authoritative authentication.
  void setAuthenticatedUser(AppUser user) {
    _currentUser = user;
    _currentRole = user.userRole;
    _isDemoMode = user.isDemoMode;
    _authState = AuthState.authenticatedWithRole;
    OneSignalService().loginUser(user.userId);
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
  void logout() {
    OneSignalService().logoutUser();
    _authRepo.signOut();
    _currentUser = null;
    _currentRole = UserRole.VARKARI;
    _authState = AuthState.unauthenticated;
    _isDemoMode = false;
    _errorMessage = null;
    _authRepo.clearToken();
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
