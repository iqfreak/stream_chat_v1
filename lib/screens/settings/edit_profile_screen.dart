import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/mock_data.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final _picker = ImagePicker();
  // Tracks a newly picked local image path (before saving)
  String? _pendingAvatarPath;

  @override
  void initState() {
    super.initState();
    final user = context.read<MockDataService>().currentUser;
    _nameController = TextEditingController(text: user.name);
    _emailController = TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(source: source, imageQuality: 80);
    if (file == null || !mounted) return;
    setState(() => _pendingAvatarPath = file.path);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().locale;
    final isArabic = lang == 'ar';
    final data = context.watch<MockDataService>();
    final user = data.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine which avatar to preview:
    // 1. Newly picked (pending) local path
    // 2. Existing local path already stored
    // 3. Network URL or empty → fall back to initials avatar
    final previewPath = _pendingAvatarPath ?? 
        (user.avatarUrl.startsWith('/') ? user.avatarUrl : null);
    final networkUrl = (previewPath == null && user.avatarUrl.isNotEmpty &&
            !user.avatarUrl.startsWith('/'))
        ? user.avatarUrl
        : null;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(isArabic ? 'تعديل الحساب' : 'Edit Profile')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ── Avatar picker ──────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      previewPath != null
                          ? CircleAvatar(
                              radius: 44,
                              backgroundImage: FileImage(File(previewPath)),
                            )
                          : networkUrl != null
                              ? CircleAvatar(
                                  radius: 44,
                                  backgroundImage: NetworkImage(networkUrl),
                                )
                              : CircleAvatar(
                                  radius: 44,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.15),
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                      Positioned(
                        bottom: 0,
                        right: isArabic ? null : 0,
                        left: isArabic ? 0 : null,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: _pickAvatar,
                  child: Text(
                    _pendingAvatarPath != null
                        ? (isArabic ? 'تغيير الصورة' : 'Change photo')
                        : (isArabic ? 'تغيير صورة الملف الشخصي' : 'Change profile photo'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── Name field ─────────────────────────────────────────────
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الاسم الكامل' : 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ── Email field ────────────────────────────────────────────
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: isArabic ? 'البريد الإلكتروني' : 'Email Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Save name + email
                    data.updateUserInfo(
                      _nameController.text,
                      _emailController.text,
                    );
                    // Save avatar if a new one was picked
                    if (_pendingAvatarPath != null) {
                      data.updateUserAvatar(_pendingAvatarPath!);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isArabic
                              ? 'تم حفظ التعديلات بنجاح!'
                              : 'Profile Updated Successfully!',
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  },
                  child: Text(
                    isArabic ? 'حفظ التعديلات' : 'Save Changes',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
