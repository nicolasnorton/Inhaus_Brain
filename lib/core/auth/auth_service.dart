import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class AuthService {
  // Check if Firebase is available. In this local demo, it is not initialized.
  final bool _isMock = true; 

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }
  
  // Lazy load GoogleSignIn to avoid web crashes on init if client ID is missing
  GoogleSignIn? _googleSignIn;

  // Mock State
  final _mockUserStreamController = StreamController<User?>.broadcast();
  User? _mockUser;

  AuthService() {
    if (_isMock) {
      // Emit null initially
      _mockUserStreamController.add(null);
    }
  }

  Stream<User?> get authStateChanges {
    if (_isMock) {
      return _mockUserStreamController.stream;
    }
    return _auth!.authStateChanges();
  }

  User? get currentUser {
    if (_isMock) return _mockUser;
    return _auth!.currentUser;
  }

  bool get isAdmin {
    final user = currentUser;
    if (user == null) return false;
    // For this demo, we consider this specific email as the system admin
    return user.email == 'nnorton@inhauscorp.com';
  }

  Future<User?> signInWithGoogle() async {
    if (_isMock) {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      // Create a Mock User (We can't instantiate User directly easily, so we cast a Mock or use a workaround)
      // Actually, we can't easily implement 'User' from firebase_auth as it's a complex class.
      // But we can return 'null' and handle it in UI? 
      // OR we can't return a real User object essentially without mocking properly.
      // Let's rely on the UI checking 'currentUser' properties.
      // A better way for the Demo: Just don't crash.
      
      // Since ProfileSettingsScreen expects a User object to show photoURL, we need something.
      // However, creating a MockUser implementation is verbose.
      // I will fallback to: returning null but printing a log, OR asking user to configure Firebase.
      // BUT to allow "Vault" access (which is local), we don't strictly NEED a User object unless we enforce it.
      // The ProfileSettingsScreen might require it.
      
      print("AuthService: Starting Mock Sign In...");
      _mockUser = MockUser(
        uid: 'mock-123',
        email: 'demo@inhaus.ai',
        displayName: 'Demo User',
        photoURL: 'https://i.pravatar.cc/150?u=mock-123',
      );
      _mockUserStreamController.add(_mockUser);
      return _mockUser;
    }

    try {
      _googleSignIn ??= GoogleSignIn(); // Init only when needed
      final GoogleSignInAccount? googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth!.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Error signing in with Google: $e");
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    if (_isMock) {
      await Future.delayed(const Duration(seconds: 1));
      print("AuthService: Mock Sign In for $email");
      
      // Special Mock Admin check
      if (email == 'nnorton@inhauscorp.com' && password == 'InhausBain333\$') {
         _mockUser = MockUser(
          uid: 'mock-admin-001',
          email: 'nnorton@inhauscorp.com',
          displayName: 'Nicolas Norton',
          photoURL: 'https://i.pravatar.cc/150?u=nicolas',
        );
      } else {
        _mockUser = MockUser(
          uid: 'mock-${email.hashCode}',
          email: email,
          displayName: email.split('@')[0],
          photoURL: 'https://i.pravatar.cc/150?u=$email',
        );
      }
      _mockUserStreamController.add(_mockUser);
      return _mockUser;
    }
    try {
      final UserCredential userCredential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Error signing in with email: $e");
      rethrow;
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String displayName) async {
    if (_isMock) {
      await Future.delayed(const Duration(seconds: 1));
      print("AuthService: Mock Sign Up for $email");
      _mockUser = MockUser(
        uid: 'mock-${email.hashCode}',
        email: email,
        displayName: displayName,
        photoURL: 'https://i.pravatar.cc/150?u=$email',
      );
      _mockUserStreamController.add(_mockUser);
      return _mockUser;
    }
    try {
      final UserCredential userCredential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(displayName);
      return userCredential.user;
    } catch (e) {
      print("Error signing up: $e");
      rethrow;
    }
  }

  Future<void> updateDisplayName(String name) async {
    if (_isMock) {
      print("AuthService: Mock Update Display Name to $name");
      if (_mockUser != null) {
        _mockUser = MockUser(
          uid: _mockUser!.uid,
          email: _mockUser!.email,
          displayName: name,
          photoURL: _mockUser!.photoURL,
        );
        _mockUserStreamController.add(_mockUser);
      }
      return;
    }
    await _auth!.currentUser?.updateDisplayName(name);
  }

  Future<void> signOut() async {
    if (_isMock) {
      _mockUser = null;
      _mockUserStreamController.add(null);
      return;
    }
    await _googleSignIn?.signOut();
    await _auth!.signOut();
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

class MockUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;
  @override
  final String? photoURL;

  MockUser({required this.uid, this.email, this.displayName, this.photoURL});

  @override
  bool get emailVerified => true;
  @override
  bool get isAnonymous => false;
  @override
  UserMetadata get metadata => throw UnimplementedError();
  @override
  String? get phoneNumber => null;
  @override
  List<UserInfo> get providerData => [];
  @override
  String? get refreshToken => null;
  @override
  String? get tenantId => null;
  @override
  Future<void> delete() async {}
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock-token';
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async => throw UnimplementedError();
  @override
  Future<void> reload() async {}
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<UserCredential> linkWithCredential(AuthCredential credential) async => throw UnimplementedError();
  @override
  Future<ConfirmationResult> linkWithPhoneNumber(String phoneNumber, [RecaptchaVerifier? verifier]) async => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithPopup(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<UserCredential> linkWithProvider(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<void> linkWithRedirect(AuthProvider provider) async => throw UnimplementedError();
  @override
  MultiFactor get multiFactor => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithPopup(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<UserCredential> reauthenticateWithProvider(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<void> reauthenticateWithRedirect(AuthProvider provider) async => throw UnimplementedError();
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}
  @override
  Future<User> unlink(String providerId) async => this;
  @override
  Future<void> updateEmail(String newEmail) async {}
  @override
  Future<void> updatePassword(String newPassword) async {}
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential credential) async {}
  @override
  Future<void> updatePhotoURL(String? photoURL) async {}
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async {}
  @override
  Future<void> updateDisplayName(String? displayName) async {}
}
