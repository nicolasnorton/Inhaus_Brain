import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../features/auth/models/user_model.dart';

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
  final Map<String, AppUser> _mockUserProfiles = {};

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
    final profile = getAppUser(user);
    return profile.role == UserRole.admin || 
           user.email == 'nnorton@inhauscorp.com' || 
           user.email == 'demo@inhaus.ai';
  }

  bool get isClient {
    final user = currentUser;
    if (user == null) return false;
    final profile = getAppUser(user);
    // Any role other than admin for this simple demo could be considered a team/client role
    return profile.role != UserRole.admin;
  }

  String? get userClientId {
    final user = currentUser;
    if (user == null) return null;
    if (isAdmin) return null; 
    
    final profile = getAppUser(user);
    if (profile.assignedClientIds.isNotEmpty) {
      return profile.assignedClientIds.first;
    }
    
    // Legacy mapping
    if (user.email == 'client@inhaus Studios.ai') return 'client-1';
    if (user.email == 'marketing@globaltech.com') return 'client-2';
    return null;
  }

  AppUser getAppUser(User user) {
    if (!_mockUserProfiles.containsKey(user.uid)) {
      // Default profile based on email
      UserRole role = UserRole.accountManager;
      List<String> clients = [];

      if (user.email == 'nnorton@inhauscorp.com' || user.email == 'demo@inhaus.ai') {
        role = UserRole.admin;
      } else if (user.email == 'client@inhaus Studios.ai') {
        clients = ['client-1'];
      } else if (user.email == 'marketing@globaltech.com') {
        clients = ['client-2'];
      }

      _mockUserProfiles[user.uid] = AppUser(
        id: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        role: role,
        assignedClientIds: clients,
      );
    }
    return _mockUserProfiles[user.uid]!;
  }

  Future<void> updateAppUser(AppUser updatedUser) async {
    _mockUserProfiles[updatedUser.id] = updatedUser;
    // Notify listeners if necessary (though appUserProvider handles it via authState)
  }

  Future<User?> signInWithGoogle() async {
    if (_isMock) {
      await Future.delayed(const Duration(seconds: 1));
      print("AuthService: Starting Mock Sign In...");
      _mockUser = MockUser(
        uid: 'mock-123',
        email: 'demo@inhaus.ai',
        displayName: 'Demo User',
        photoURL: null,
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
          photoURL: null,
        );
      } else if (email == 'studio@inhaus.ai') {
         _mockUser = MockUser(
          uid: 'mock-client-1',
          email: 'studio@inhaus.ai',
          displayName: 'Inhaus Studio Admin',
          photoURL: null,
        );
      } else if (email == 'marketing@globaltech.com') {
         _mockUser = MockUser(
          uid: 'mock-client-2',
          email: 'marketing@globaltech.com',
          displayName: 'Global Tech Marketing',
          photoURL: null,
        );
      } else {
        _mockUser = MockUser(
          uid: 'mock-${email.hashCode}',
          email: email,
          displayName: email.split('@')[0],
          photoURL: null,
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

final appUserProvider = Provider<AppUser?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getAppUser(user);
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
