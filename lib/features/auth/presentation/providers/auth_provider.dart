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
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          // Jika login gagal karena user belum terdaftar, buat akun baru otomatis (logic asli)
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
          throw 'Password yang Anda masukkan salah. Silakan coba lagi.';
        } else if (e.code == 'too-many-requests') {
          throw 'Terlalu banyak percobaan masuk. Silakan coba beberapa saat lagi.';
        } else {
          rethrow;
        }
      }
      state = state.copyWith(isLoading: false);
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan saat masuk. Silakan coba lagi.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah terdaftar dengan password berbeda.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Kata sandi terlalu lemah (minimal 6 karakter).';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Password yang Anda masukkan salah. Silakan coba lagi.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Terlalu banyak percobaan masuk. Silakan coba beberapa saat lagi.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Akun ini telah dinonaktifkan.';
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
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
