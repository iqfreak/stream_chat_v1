import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

/// Central translation table for the whole app (English + Arabic).
///
/// Usage in any widget:
///   AppStrings.t(context, 'channels')
/// or, if you only have the language code:
///   AppStrings.of('ar', 'channels')
class AppStrings {
  AppStrings._();

  static String t(BuildContext context, String key) {
    final lang = context.read<AppState>().locale;
    return of(lang, key);
  }

  static String of(String lang, String key) {
    final table = lang == 'ar' ? _ar : _en;
    return table[key] ?? _en[key] ?? key;
  }

  // English -------------------------------------------------------------
  static const Map<String, String> _en = {
    // Bottom nav
    'nav_chats': 'Chats',
    'nav_search': 'Search',
    'nav_notifications': 'Notifications',
    'nav_settings': 'Settings',

    // Channel list
    'channels_title': 'Chats',
    'no_chats': 'No conversations yet',
    'no_chats_sub': 'Start a new chat to begin messaging',
    'new_chat': 'New Chat',
    'you': 'You',
    'typing': 'typing...',

    // Create channel
    'create_chat_title': 'New Chat',
    'direct_message': 'Direct Message',
    'group_chat': 'Group Chat',
    'group_name': 'Group name',
    'select_members': 'Select members',
    'search_people': 'Search people',
    'create': 'Create',
    'no_users': 'No users found',

    // Chat
    'message_hint': 'Message...',
    'no_messages': 'No messages yet',
    'say_hi': 'Say hi to start the conversation',
    'not_member': 'You are not a member of this group and cannot send messages.',
    'pinned_message': 'Pinned message',
    'pinned_messages': 'Pinned messages',
    'edited': 'edited',
    'reply_in_thread': 'Reply in Thread',
    'replies': 'replies',
    'reply': 'reply',

    // Message actions
    'react': 'React',
    'edit': 'Edit',
    'delete': 'Delete',
    'forward': 'Forward',
    'pin': 'Pin',
    'unpin': 'Unpin',
    'copy': 'Copy',
    'forward_to': 'Forward to',
    'edit_message': 'Edit message',
    'save': 'Save',
    'cancel': 'Cancel',
    'block_user': 'Block User',
    'block_user_sub': 'Hide their messages from you',

    // Thread
    'thread': 'Thread',
    'thread_reply_hint': 'Reply...',

    // Search
    'search_title': 'Search',
    'search_hint': 'Search messages...',
    'filter_all': 'All',
    'filter_text': 'Text',
    'filter_photos': 'Photos',
    'filter_videos': 'Videos',
    'filter_files': 'Files',
    'search_empty': 'Search your messages',
    'search_empty_sub': 'Find messages, photos, videos and files',
    'no_results': 'No results found',
    'no_items': 'No items found',

    // Notifications
    'notifications_title': 'Notifications',
    'no_notifications': 'No notifications',
    'no_notifications_sub': 'You are all caught up',
    'mentioned_you_in': ' mentioned you in ',
    'messaged_you_in': ' messaged you in ',
    'mark_all_read': 'Mark all read',

    // Auth
    'login_title': 'Welcome Back',
    'login_sub': 'Sign in to continue',
    'register_title': 'Create Account',
    'register_sub': 'Sign up to get started',
    'email': 'Email',
    'password': 'Password',
    'display_name': 'Display Name',
    'login': 'Login',
    'register': 'Register',
    'no_account': "Don't have an account? Register",
    'have_account': 'Already have an account? Login',
    'invalid_credentials': 'Invalid email or password',

    // Settings
    'settings_title': 'Settings & Profile',
    'edit_profile': 'Edit Profile',
    'appearance': 'Appearance',
    'dark_mode': 'Dark Mode',
    'enabled': 'Enabled',
    'disabled': 'Disabled',
    'language': 'Language',
    'notifications': 'Notifications',
    'push_notif': 'Push Notifications',
    'all_msgs': 'All messages',
    'account': 'Account',
    'security': 'Account & Security',
    'security_sub': 'Password, delete account',
    'help': 'Help & Support',
    'about': 'About',
    'sign_out': 'Sign Out',
    'sign_out_confirm': 'Are you sure you want to sign out?',

    // Account & security / delete
    'change_email': 'Change Email',
    'change_password': 'Change Password',
    'delete_account': 'Delete Account',
    'delete_account_sub': 'Permanently delete your account',
    'delete_account_warning':
        'This will permanently delete your account and sign you out. This action cannot be undone.',
    'enter_password_confirm': 'Enter your password to confirm',
    'delete_my_account': 'Delete My Account',
    'wrong_password': 'Incorrect password',
    'account_deleted': 'Your account has been deleted',
  };

  // Arabic --------------------------------------------------------------
  static const Map<String, String> _ar = {
    'nav_chats': 'المحادثات',
    'nav_search': 'بحث',
    'nav_notifications': 'الإشعارات',
    'nav_settings': 'الإعدادات',

    'channels_title': 'المحادثات',
    'no_chats': 'لا توجد محادثات بعد',
    'no_chats_sub': 'ابدأ محادثة جديدة للبدء',
    'new_chat': 'محادثة جديدة',
    'you': 'أنت',
    'typing': 'يكتب...',

    'create_chat_title': 'محادثة جديدة',
    'direct_message': 'رسالة مباشرة',
    'group_chat': 'مجموعة',
    'group_name': 'اسم المجموعة',
    'select_members': 'اختر الأعضاء',
    'search_people': 'ابحث عن أشخاص',
    'create': 'إنشاء',
    'no_users': 'لا يوجد مستخدمون',

    'message_hint': 'رسالة...',
    'no_messages': 'لا توجد رسائل بعد',
    'say_hi': 'ابدأ المحادثة بالترحيب',
    'not_member': 'أنت لست عضوًا في هذه المجموعة ولا يمكنك إرسال رسائل.',
    'pinned_message': 'رسالة مثبتة',
    'pinned_messages': 'رسائل مثبتة',
    'edited': 'تم التعديل',
    'reply_in_thread': 'رد في المحادثة',
    'replies': 'ردود',
    'reply': 'رد',

    'react': 'تفاعل',
    'edit': 'تعديل',
    'delete': 'حذف',
    'forward': 'إعادة توجيه',
    'pin': 'تثبيت',
    'unpin': 'إلغاء التثبيت',
    'copy': 'نسخ',
    'forward_to': 'إعادة توجيه إلى',
    'edit_message': 'تعديل الرسالة',
    'save': 'حفظ',
    'cancel': 'إلغاء',
    'block_user': 'حظر المستخدم',
    'block_user_sub': 'إخفاء رسائله عنك',

    'thread': 'المحادثة',
    'thread_reply_hint': 'رد...',

    'search_title': 'بحث',
    'search_hint': 'ابحث في الرسائل...',
    'filter_all': 'الكل',
    'filter_text': 'نص',
    'filter_photos': 'صور',
    'filter_videos': 'فيديوهات',
    'filter_files': 'ملفات',
    'search_empty': 'ابحث في رسائلك',
    'search_empty_sub': 'ابحث عن رسائل وصور وفيديوهات وملفات',
    'no_results': 'لا توجد نتائج',
    'no_items': 'لا توجد عناصر',

    'notifications_title': 'الإشعارات',
    'no_notifications': 'لا توجد إشعارات',
    'no_notifications_sub': 'أنت على اطلاع بكل شيء',
    'mentioned_you_in': ' أشار إليك في ',
    'messaged_you_in': ' راسلك في ',
    'mark_all_read': 'تعليم الكل كمقروء',

    'login_title': 'مرحبًا بعودتك',
    'login_sub': 'سجّل الدخول للمتابعة',
    'register_title': 'إنشاء حساب',
    'register_sub': 'سجّل للبدء',
    'email': 'البريد الإلكتروني',
    'password': 'كلمة المرور',
    'display_name': 'الاسم المعروض',
    'login': 'تسجيل الدخول',
    'register': 'تسجيل',
    'no_account': 'ليس لديك حساب؟ سجّل',
    'have_account': 'لديك حساب بالفعل؟ سجّل الدخول',
    'invalid_credentials': 'بريد إلكتروني أو كلمة مرور غير صحيحة',

    'settings_title': 'الإعدادات والملف الشخصي',
    'edit_profile': 'تعديل الحساب',
    'appearance': 'المظهر',
    'dark_mode': 'الوضع الداكن',
    'enabled': 'مفعل',
    'disabled': 'معطل',
    'language': 'اللغة',
    'notifications': 'الإشعارات',
    'push_notif': 'إشعارات التطبيق',
    'all_msgs': 'كل الرسائل',
    'account': 'الحساب',
    'security': 'الحساب والأمان',
    'security_sub': 'كلمة المرور، حذف الحساب',
    'help': 'المساعدة والدعم',
    'about': 'عن التطبيق',
    'sign_out': 'تسجيل الخروج',
    'sign_out_confirm': 'هل أنت متأكد أنك تريد تسجيل الخروج؟',

    'change_email': 'تغيير البريد الإلكتروني',
    'change_password': 'تغيير كلمة المرور',
    'delete_account': 'حذف الحساب',
    'delete_account_sub': 'حذف حسابك نهائيًا',
    'delete_account_warning':
        'سيؤدي هذا إلى حذف حسابك نهائيًا وتسجيل خروجك. لا يمكن التراجع عن هذا الإجراء.',
    'enter_password_confirm': 'أدخل كلمة المرور للتأكيد',
    'delete_my_account': 'حذف حسابي',
    'wrong_password': 'كلمة المرور غير صحيحة',
    'account_deleted': 'تم حذف حسابك',
  };
}
