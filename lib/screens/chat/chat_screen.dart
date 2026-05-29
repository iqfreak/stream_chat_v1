import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:file_picker/file_picker.dart'; // 🛠️ تم التحديث واستخدام file_picker
import '../../services/stream_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_avatar.dart';
import 'message_action_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String channelId;
  const ChatScreen({super.key, required this.channelId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StreamChatService>().markChannelRead(widget.channelId);
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final data = context.read<StreamChatService>();
    final channel = data.channelById(widget.channelId);
    if (channel == null) return;
    if (!channel.memberIds.contains(data.currentUser.id)) {
      _showNotMemberSnackbar();
      return;
    }
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    data.sendMessage(widget.channelId, text);
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showNotMemberSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You are not a member of this group.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // 🛠️ تم تعديل الميثود بالكامل لدعم جميع أنواع الملفات
  Future<void> _attach() async {
    final data = context.read<StreamChatService>();
    final channel = data.channelById(widget.channelId);
    if (channel == null) return;
    if (!channel.memberIds.contains(data.currentUser.id)) {
      _showNotMemberSnackbar();
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.any, // 🛠️ يسمح باختيار أي نوع ملف
      );

      if (result != null && mounted) {
        // تجهيز قائمة المرفقات
        List<AppAttachment> attachments = result.files.map((file) {
          // تحديد نوع الملف مبدئياً للـ UI
          String fileType = 'file';
          final ext = file.extension?.toLowerCase();
          if (ext == 'jpg' ||
              ext == 'jpeg' ||
              ext == 'png' ||
              ext == 'gif' ||
              ext == 'webp') {
            fileType = 'image';
          } else if (ext == 'mp4' || ext == 'avi' || ext == 'mov') {
            fileType = 'video';
          } else if (ext == 'mp3' || ext == 'wav' || ext == 'm4a') {
            fileType = 'audio';
          }

          return AppAttachment(
            type: fileType,
            name: file.name,
            url: file.path!,
          );
        }).toList();

        // إرسال الرسالة مع المرفقات
        context.read<StreamChatService>().sendMessageWithAttachment(
          widget.channelId,
          '',
          attachments,
        );

        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
    }
  }

  void _showActionSheet(AppMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          MessageActionSheet(message: msg, channelId: widget.channelId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<StreamChatService>();
    final channel = data.channelById(widget.channelId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (channel == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Channel not found')),
      );
    }

    final me = data.currentUser;
    final isMember = channel.memberIds.contains(me.id);

    AppUser? otherUser;
    if (!channel.isGroup) {
      otherUser = channel.memberIds
          .where((id) => id != me.id)
          .map((id) => data.userById(id))
          .whereType<AppUser>()
          .firstOrNull;
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/channels')),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => context.push('/channels/${widget.channelId}/info'),
          child: Row(
            children: [
              if (channel.isGroup)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.group, color: Colors.white, size: 18),
                )
              else
                UserAvatar(
                  name: otherUser?.name ?? channel.name,
                  avatarUrl: otherUser?.avatarUrl,
                  size: 36,
                  showOnline: otherUser?.isOnline ?? false,
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.isGroup
                          ? channel.name
                          : (otherUser?.name ?? channel.name),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!channel.isGroup && otherUser != null)
                      Text(
                        otherUser.isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 11,
                          color: otherUser.isOnline
                              ? AppColors.online
                              : (isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textLightSecondary),
                        ),
                      )
                    else if (channel.isGroup)
                      Text(
                        '${channel.memberIds.length} members',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push('/channels/${widget.channelId}/info'),
          ),
        ],
      ),
      body: Column(
        children: [
          if (channel.isGroup && !isMember)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: isDark ? AppColors.darkCard : const Color(0xFFFFF3CD),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : const Color(0xFF856404),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You are not a member of this group and cannot send messages.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textDarkSecondary
                            : const Color(0xFF856404),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: channel.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Say hello! 👋',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textLightSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: channel.messages.length,
                    itemBuilder: (context, i) {
                      final msg = channel.messages[i];
                      final isMine = msg.senderId == me.id;
                      final sender = data.userById(msg.senderId);

                      final showHeader =
                          i == 0 ||
                          channel.messages[i - 1].senderId != msg.senderId;

                      return _MessageBubble(
                        message: msg,
                        isMine: isMine,
                        sender: sender,
                        showHeader: showHeader,
                        isDark: isDark,
                        channelId: widget.channelId,
                        onLongPress: () => _showActionSheet(msg),
                        onThreadTap: () => context.push(
                          '/channels/${widget.channelId}/chat/${msg.id}/thread',
                        ),
                      );
                    },
                  ),
          ),
          _buildInputArea(context, isDark, isMember, channel.isGroup),
        ],
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    bool isDark,
    bool isMember,
    bool isGroup,
  ) {
    if (isGroup && !isMember) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkAppBar : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 16,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textLightSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'You cannot send messages in this group.',
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkAppBar : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkDivider : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: Icon(
                Icons.attach_file,
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textLightSecondary,
              ),
              onPressed: _attach,
            ),
            Expanded(
              child: TextField(
                controller: _inputCtrl,
                maxLines: 6,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  filled: true,
                  fillColor: isDark
                      ? AppColors.darkCard
                      : const Color(0xFFF0F2F5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _send,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Message Bubble ──────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final AppMessage message;
  final bool isMine;
  final AppUser? sender;
  final bool showHeader;
  final bool isDark;
  final String channelId;
  final VoidCallback onLongPress;
  final VoidCallback onThreadTap;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.sender,
    required this.showHeader,
    required this.isDark,
    required this.channelId,
    required this.onLongPress,
    required this.onThreadTap,
  });

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMine
        ? AppColors.sentBubble
        : (isDark
              ? AppColors.receivedBubbleDark
              : AppColors.receivedBubbleLight);
    final textColor = isMine
        ? Colors.white
        : (isDark ? AppColors.textDark : AppColors.textLight);

    return Padding(
      padding: EdgeInsets.only(top: showHeader ? 12 : 2, bottom: 2),
      child: Row(
        mainAxisAlignment: isMine
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            if (showHeader)
              UserAvatar(
                name: sender?.name ?? '?',
                avatarUrl: sender?.avatarUrl,
                size: 28,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.72,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: message.isDeleted
                      ? (isDark ? AppColors.darkCard : const Color(0xFFF5F6FA))
                      : bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(
                      isMine ? 18 : (showHeader ? 4 : 18),
                    ),
                    bottomRight: Radius.circular(
                      isMine ? (showHeader ? 4 : 18) : 18,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader && !isMine)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          sender?.name ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (message.isDeleted)
                      Text(
                        'This message was deleted',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textLightSecondary,
                        ),
                      )
                    else ...[
                      // 🛠️ التعديل هنا: استخدام Widget يفرق بين الصور والملفات
                      ...message.attachments.map(
                        (a) => _FileAttachmentWidget(
                          attachment: a,
                          isDark: isDark,
                          textColor: textColor,
                        ),
                      ),
                      if (message.displayText.isNotEmpty)
                        Text(
                          message.displayText,
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            fontStyle: FontStyle.normal,
                          ),
                        ),
                    ],
                    if (message.reactions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _ReactionsRow(
                          message: message,
                          channelId: channelId,
                        ),
                      ),
                    if (message.threadReplies.isNotEmpty)
                      GestureDetector(
                        onTap: onThreadTap,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.forum,
                                size: 14,
                                color: isMine
                                    ? Colors.white70
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${message.threadReplies.length} ${message.threadReplies.length == 1 ? 'reply' : 'replies'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isMine
                                      ? Colors.white70
                                      : AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              Icons.push_pin,
                              size: 10,
                              color: isMine
                                  ? Colors.white70
                                  : AppColors.primary,
                            ),
                          ),
                        if (message.editedText != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              'edited',
                              style: TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: isMine
                                    ? Colors.white70
                                    : (isDark
                                          ? AppColors.textDarkSecondary
                                          : AppColors.textLightSecondary),
                              ),
                            ),
                          ),
                        Text(
                          timeago.format(message.createdAt, allowFromNow: true),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMine
                                ? Colors.white70
                                : (isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textLightSecondary),
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead ? Icons.done_all : Icons.check,
                            size: 12,
                            color: message.isRead
                                ? Colors.lightBlueAccent
                                : Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── File Attachment Widget ──────────────────────────────────────────────────
// 🛠️ كلاس جديد لعرض الصور كصور، والملفات الأخرى كأيقونات قابلة للتحميل/الفتح
class _FileAttachmentWidget extends StatelessWidget {
  final AppAttachment attachment;
  final bool isDark;
  final Color textColor;

  const _FileAttachmentWidget({
    required this.attachment,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (attachment.type == 'image') {
      return _ImageAttachment(attachment: attachment, isDark: isDark);
    }

    // إذا كان الملف ليس صورة (PDF، ZIP، Audio، إلخ)
    IconData fileIcon = Icons.insert_drive_file;
    if (attachment.type == 'video') fileIcon = Icons.video_file;
    if (attachment.type == 'audio') fileIcon = Icons.audio_file;
    if (attachment.name.toLowerCase().endsWith('.pdf'))
      fileIcon = Icons.picture_as_pdf;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(fileIcon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              attachment.name,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Image Attachment ────────────────────────────────────────────────────────

class _ImageAttachment extends StatelessWidget {
  final AppAttachment attachment;
  final bool isDark;
  const _ImageAttachment({required this.attachment, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isLocal =
        attachment.url.startsWith('/') || attachment.url.startsWith('file://');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: isLocal
            ? Image.file(
                File(attachment.url),
                width: 220,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _BrokenImage(isDark: isDark),
              )
            : Image.network(
                attachment.url,
                width: 220,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _BrokenImage(isDark: isDark),
              ),
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  final bool isDark;
  const _BrokenImage({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.broken_image_outlined,
        size: 48,
        color: isDark
            ? AppColors.textDarkSecondary
            : AppColors.textLightSecondary,
      ),
    );
  }
}

// ─── Reactions Row ───────────────────────────────────────────────────────────

class _ReactionsRow extends StatelessWidget {
  final AppMessage message;
  final String channelId;

  const _ReactionsRow({required this.message, required this.channelId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final data = context.read<StreamChatService>();

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: message.reactions.map((r) {
        final mine = r.userIds.contains(data.currentUser.id);
        return GestureDetector(
          onTap: () => data.toggleReaction(channelId, message.id, r.emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: mine
                  ? AppColors.primary.withOpacity(0.2)
                  : (isDark
                        ? AppColors.reactionBg
                        : Colors.grey.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(12),
              border: mine
                  ? Border.all(color: AppColors.primary.withOpacity(0.5))
                  : null,
            ),
            child: Text(
              '${r.emoji} ${r.userIds.length}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      }).toList(),
    );
  }
}
