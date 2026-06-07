import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:async';
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
  StreamSubscription? _authSubscription;
  StreamSubscription? _userDocSubscription;

  AuthNotifier() : super(AuthState()) {
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  void _checkAutoLogin() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        state = state.copyWith(
          isAuthenticated: true,
          userId: user.uid,
          email: user.email,
          name: user.displayName ?? 'Peternak',
          photoUrl: user.photoURL,
        );
        _listenToUserDoc(user.uid);
      } else {
        _userDocSubscription?.cancel();
        state = AuthState();
      }
    });
  }

  void _listenToUserDoc(String uid) {
    _userDocSubscription?.cancel();
    _userDocSubscription = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          state = state.copyWith(
            name: data['name'] ?? state.name,
            photoUrl: data['photoURL'] ?? state.photoUrl,
          );
        }
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
        
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': name,
          if (photoPath != null) 'photoURL': photoPath,
        }, SetOptions(merge: true));

        state = state.copyWith(
          name: name,
          photoUrl: photoPath ?? state.photoUrl,
        );
      }
    } catch (e) {
      state = state.copyWith(error: 'Gagal memperbarui profil: \$e');
    }
  }

  Future<void> uploadProfilePicture(String localPath) async {
    if (state.userId == null) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Compress image
      final compressedData = await FlutterImageCompress.compressWithFile(
        localPath,
        minWidth: 800,
        minHeight: 800,
        quality: 85,
      );

      if (compressedData == null) throw 'Gagal mengompresi gambar.';

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref().child('profiles/${user.uid}/avatar.jpg');
      
      final uploadTask = storageRef.putData(
        compressedData,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save to Firestore and Auth
      await user.updatePhotoURL(downloadUrl);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'photoURL': downloadUrl,
      }, SetOptions(merge: true));

      state = state.copyWith(
        photoUrl: downloadUrl,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Gagal mengunggah foto profil. Silakan coba lagi.',
      );
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
