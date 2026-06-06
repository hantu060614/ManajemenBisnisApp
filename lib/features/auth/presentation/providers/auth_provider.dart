import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;
  
  final String? userId;
  final String? name;
  final String? email;
  final String? photoUrl;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
    this.userId,
    this.name,
    this.email,
    this.photoUrl,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
    String? userId,
    String? name,
    String? email,
    String? photoUrl,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkAutoLogin();
  }

  void _checkAutoLogin() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          userId: user.uid,
          email: user.email,
          name: user.displayName ?? 'Peternak',
          photoUrl: user.photoURL,
        );
      } else {
        state = AuthState();
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } catch (e) {
        // Jika login gagal (kemungkinan akun belum ada), buat akun baru otomatis
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateProfile(String name, String? photoPath) async {
    if (state.userId == null) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        if (photoPath != null) {
          await user.updatePhotoURL(photoPath);
        }
        state = state.copyWith(
          name: name,
          photoUrl: photoPath ?? state.photoUrl,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Gagal memperbarui profil: \$e');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.email != null) {
        // Re-authenticate
        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(cred);
        
        // Update password
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      throw Exception('Gagal mengubah kata sandi. Pastikan sandi lama benar.');
    }
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
    state = AuthState();
  }
}
