import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/stream_chat_service.dart';
import '../../providers/app_state.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  final _picker = ImagePicker();
  String? _pendingAvatarPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<StreamChatService>().currentUser;
    _nameController = TextEditingController(text: user.name);
    // تمت إزالة _usernameController لأنه لا يتغير
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    if (file != null && mounted) setState(() => _pendingAvatarPath = file.path);
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });
    final data = context.read<StreamChatService>();
    final isArabic = context.read<AppState>().locale == 'ar';

    // التحديث للاسم والصورة فقط
    data.updateUserInfo(_nameController.text, data.currentUser.email);
    if (_pendingAvatarPath != null) data.updateUserAvatar(_pendingAvatarPath!);

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم حفظ التعديلات بنجاح!'
                : 'Profile Updated Successfully!',
          ),
        ),
      );
      Navigator.pop(context); // الرجوع بعد الحفظ
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().locale;
    final isArabic = lang == 'ar';
    final user = context.watch<StreamChatService>().currentUser;
    final previewPath =
        _pendingAvatarPath ??
        (user.avatarUrl.startsWith('/') ? user.avatarUrl : null);
    final networkUrl =
        (previewPath == null &&
            user.avatarUrl.isNotEmpty &&
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
                              backgroundColor: Colors.blue.withValues(alpha: 0.15),
                              child: Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue,
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
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // عرض الـ Username كنص غير قابل للتعديل
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alternate_email, color: Colors.grey),
                    const SizedBox(width: 12),
                    Text(
                      user.id,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الاسم الكامل' : 'Full Name',
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
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _saveProfile,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isArabic ? 'حفظ التعديلات' : 'Save Changes',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
