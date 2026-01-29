import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../../features/auth/models/user_model.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode
import 'secret_vault_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SecretVaultService _vault = SecretVaultService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/cloud-platform',
    ],
  );

  AuthService() {
    // Listen for Google Sign-In changes (especially for GIS on Web)
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? googleUser) async {
      if (googleUser != null) {
        try {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          
          // Phase 89: Save OAuth Access Token to Vault for Vertex AI access
          if (googleAuth.accessToken != null) {
            await _vault.saveVertexKey(googleAuth.accessToken!);
            if (kDebugMode) print('AuthService: Saved new Google Access Token to Vault.');
          }

          final OAuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          
          final UserCredential userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            await getAppUser(userCredential.user!);
          }
        } catch (e) {
          if (kDebugMode) print('Error signing into Firebase with Google Credential: $e');
        }
      }
    });
  }

  // Cached User Profile
  final Map<String, AppUser> _userProfiles = {};

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<bool> get isAdmin async {
    final user = currentUser;
    if (user == null) return false;
    final profile = await getAppUser(user);
    return profile.role == UserRole.superAdmin || profile.role == UserRole.admin;
  }

  Future<bool> get isSuperAdmin async {
    final user = currentUser;
    if (user == null) return false;
    final profile = await getAppUser(user);
    return profile.role == UserRole.superAdmin;
  }

  Future<AppUser> getAppUser(User user) async {
    if (_userProfiles.containsKey(user.uid)) {
      return _userProfiles[user.uid]!;
    }

    try {
      if (kDebugMode) print('AuthService: Fetching user profile for ${user.uid}...');
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (kDebugMode) print('AuthService: Profile fetch status: ${doc.exists ? "EXISTS" : "MISSING"}');
      
      if (doc.exists && doc.data() != null) {
        final profile = AppUser.fromJson(doc.data()!);
        _userProfiles[user.uid] = profile;
        return profile;
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('Error fetching user profile: $e');
        print('Stack trace: $stack');
      }
    }

    // Fallback / First time creation
    UserRole role = UserRole.clientUser; // Default Secure Role
    if (user.email != null && (user.email!.endsWith('@inhauscorp.com') || user.email!.endsWith('@inhaus.agency'))) {
      role = UserRole.humanAgencyStaff;
    }
    
    // Bootstrap Super Admin
    if (user.email == 'nnorton@inhauscorp.com') {
      role = UserRole.superAdmin;
    }

    final newProfile = AppUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      role: role,
    );
    
    // Save to Firestore asynchronously
    _syncUserWithFirestore(newProfile);
    
    _userProfiles[user.uid] = newProfile;
    return newProfile;
  }

  Future<void> updateAppUser(AppUser user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
        user.toJson(), 
        SetOptions(merge: true),
      );
      
      // Update cache
      _userProfiles[user.id] = user;
    } catch (e) {
      if (kDebugMode) print('Error syncing user to Firestore: $e');
      rethrow;
    }
  }

  // Internal helper
  Future<void> _syncUserWithFirestore(AppUser user) => updateAppUser(user);

  /// User Management (Admin Only)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').orderBy('email').get();
      return snapshot.docs.map((doc) => AppUser.fromJson(doc.data())).toList();
    } catch (e) {
      if (kDebugMode) print('Error fetching all users: $e');
      rethrow;
    }
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': role.name,
      });
      // Clear from profile cache to force refresh on next fetch
      _userProfiles.remove(userId);
    } catch (e) {
      if (kDebugMode) print('Error updating user role: $e');
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      
      if (user != null) {
        // Ensure profile exists/is up to date
        await getAppUser(user);
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
       if (kDebugMode) print('Firebase Auth Error (Google): ${e.code} - ${e.message}');
       rethrow;
    } catch (e) {
      if (kDebugMode) print('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      // Bootstrap Logic: If this is the specific requested admin user, try to auto-create if login fails
      if (email == 'nnorton@inhauscorp.com' && password == 'Cafeina88\$') {
        try {
          final userCredential = await _auth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          final user = userCredential.user;
          if (user != null) await getAppUser(user);
          return user;
        } catch (e) {
          if (e is FirebaseAuthException && (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'invalid-email')) {
            // Check if user exists but has different password? 
            // For now, assume if it fails, we should try to sign up as requested.
            return await signUpWithEmail(email, password, 'Nicolas Norton');
          }
          rethrow;
        }
      }

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
       if (user != null) {
        await getAppUser(user);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signUpWithEmail(String email, String password, String displayName) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await user.updateDisplayName(displayName);
        // Force profile creation
        final newUser = AppUser(
            id: user.uid,
            email: email,
            displayName: displayName,
        // Determine role based on domain
        UserRole initialRole = UserRole.clientUser;
        if (email.endsWith('@inhauscorp.com') || email.endsWith('@inhaus.agency')) {
          initialRole = UserRole.humanAgencyStaff;
        }

        final newUser = AppUser(
            id: user.uid,
            email: email,
            displayName: displayName,
            role: initialRole,
        );
         _userProfiles[user.uid] = newUser;
        await _syncUserWithFirestore(newUser);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    _userProfiles.clear();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Refreshes the Google OAuth token if the user is signed in.
  /// Used by Vertex AI services to ensure valid credentials.
  Future<String?> getFreshVertexToken() async {
    try {
      final googleUser = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (googleUser != null) {
        final auth = await googleUser.authentication;
        if (auth.accessToken != null) {
           await _vault.saveVertexKey(auth.accessToken!);
           return auth.accessToken;
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error refreshing Vertex Token: $e');
    }
    return null;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Async value provider is better for firestore fetches
final appUserProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return null;
  
  return ref.read(authServiceProvider).getAppUser(authState);
});
