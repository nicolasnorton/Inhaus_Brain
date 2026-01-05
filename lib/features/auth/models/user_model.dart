enum UserRole {
  admin,
  accountManager,
  designer,
  socialMediaManager,
  adManager
}

class AppUser {
  final String id;
  final String email;
  final UserRole role;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
  });
}
