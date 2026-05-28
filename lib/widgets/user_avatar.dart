import 'dart:io';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double size;
  final bool showOnline;

  const UserAvatar({
    super.key,
    this.avatarUrl,
    required this.name,
    this.size = 40,
    this.showOnline = false,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color _avatarColor() {
    final colors = [
      const Color(0xFF005FFF),
      const Color(0xFF7B61FF),
      const Color(0xFF00C3FF),
      const Color(0xFF20E070),
      const Color(0xFFFF7A00),
      const Color(0xFFFF4B4B),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  /// Returns the correct [ImageProvider] for a given URL:
  /// - Local file paths (start with '/') → [FileImage]
  /// - Everything else → [NetworkImage]
  ImageProvider? _imageProvider() {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;
    if (avatarUrl!.startsWith('/')) return FileImage(File(avatarUrl!));
    return NetworkImage(avatarUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final provider = _imageProvider();
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: _avatarColor(),
          backgroundImage: provider,
          onBackgroundImageError: provider != null ? (error, stack) {} : null,
          child: provider == null
              ? Text(
                  _initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.36,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        if (showOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
