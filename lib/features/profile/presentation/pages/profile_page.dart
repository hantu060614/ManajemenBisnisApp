import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';


class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await ref.read(authProvider.notifier).uploadProfilePicture(pickedFile.path);
      if (mounted) {
        final error = ref.read(authProvider).error;
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto profil berhasil diperbarui!')));
        }
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ubah Kata Sandi'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  TextField(
                    controller: oldPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi Lama',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Kata Sandi Baru',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (oldPasswordController.text.isEmpty || newPasswordController.text.isEmpty) {
                            setState(() {
                              errorMessage = 'Harap isi semua kolom';
                            });
                            return;
                          }
                          setState(() {
                            isLoading = true;
                            errorMessage = null;
                          });
                          try {
                            await ref.read(authProvider.notifier).changePassword(
                                  oldPasswordController.text,
                                  newPasswordController.text,
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kata sandi berhasil diubah!')),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isLoading = false;
                              errorMessage = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (!_isEditing && _nameController.text.isEmpty) {
      _nameController.text = authState.name ?? '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                ref.read(authProvider.notifier).updateProfile(
                  _nameController.text,
                  null,
                );
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                    backgroundImage: authState.photoUrl != null && authState.photoUrl!.startsWith('http')
                        ? CachedNetworkImageProvider(authState.photoUrl!)
                        : null,
                    child: authState.isLoading
                        ? const CircularProgressIndicator()
                        : (authState.photoUrl == null || !authState.photoUrl!.startsWith('http')) 
                            ? const Icon(Icons.person, size: 60, color: AppColors.primary) 
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            if (_isEditing)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline, color: AppColors.primary),
                title: const Text('Nama Lengkap', style: TextStyle(color: Colors.grey)),
                subtitle: Text(
                  authState.name ?? 'Belum diatur',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.email_outlined, color: AppColors.primary),
              title: const Text('Email', style: TextStyle(color: Colors.grey)),
              subtitle: Text(
                authState.email ?? 'Tidak ada email',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.lock_outline, color: AppColors.primary),
              title: const Text('Keamanan', style: TextStyle(color: Colors.grey)),
              subtitle: Text(
                'Ubah Kata Sandi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showChangePasswordDialog(context),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Keluar (Log Out)', style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
