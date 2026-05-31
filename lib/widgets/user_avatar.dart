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
    if (name.isEmpty) return colors[0];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    final isLocal = hasImage && avatarUrl!.startsWith('/');

    Widget initials() => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          color: _avatarColor(),
          child: Text(
            _initials,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.36,
              fontWeight: FontWeight.w700,
            ),
          ),
        );

    Widget avatarChild;
    if (!hasImage) {
      avatarChild = initials();
    } else if (isLocal) {
      avatarChild = Image.file(
        File(avatarUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initials(),
      );
    } else {
      avatarChild = Image.network(
        avatarUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => initials(),
      );
    }

    return Stack(
      children: [
        ClipOval(
          child: SizedBox(width: size, height: size, child: avatarChild),
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
