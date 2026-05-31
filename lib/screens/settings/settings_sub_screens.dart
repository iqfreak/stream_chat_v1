import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';
import '../../services/stream_chat_service.dart';
import '../../widgets/user_avatar.dart';
import '../../utils/app_strings.dart';

// ======================= Account & Security =======================
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.t(context, 'security'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: Text(AppStrings.t(context, 'change_email')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(AppStrings.t(context, 'change_password')),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});
  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _confirmEmailController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = context.read<StreamChatService>().currentEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _confirmEmailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context.read<StreamChatService>().changeEmail(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'New Email',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val != null && !val.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Email',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val != _emailController.text
                    ? 'Emails do not match!'
                    : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Email'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final error = await context.read<StreamChatService>().changePassword(
      '',
      _newPassController.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val != null && val.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val != _newPassController.text
                    ? 'Passwords do not match!'
                    : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= Privacy =======================
class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _profileVisibility = true;
  bool _readReceipts = true;
  int _blockedCount = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final blocked = await context.read<StreamChatService>().blockedUsers();
    if (!mounted) return;
    setState(() {
      _profileVisibility = prefs.getBool('sc_profile_visibility') ?? true;
      _readReceipts = prefs.getBool('sc_read_receipts') ?? true;
      _blockedCount = blocked.length;
    });
  }

  Future<void> _setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.visibility),
            title: const Text('Profile Visibility'),
            subtitle: const Text('Make your profile public'),
            value: _profileVisibility,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _profileVisibility = val);
              _setBool('sc_profile_visibility', val);
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.mark_chat_read),
            title: const Text('Read Receipts'),
            subtitle: const Text(
              'Let others know when you read their messages',
            ),
            value: _readReceipts,
            activeThumbColor: AppColors.primary,
            onChanged: (val) {
              setState(() => _readReceipts = val);
              _setBool('sc_read_receipts', val);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Blocked Users'),
            trailing: Text(
              '$_blockedCount',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
              );
              _load();
            },
          ),
        ],
      ),
    );
  }
}

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<AppUser> _blocked = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final blocked = await context.read<StreamChatService>().blockedUsers();
    if (!mounted) return;
    setState(() {
      _blocked = blocked;
      _loading = false;
    });
  }

  Future<void> _unblock(AppUser user) async {
    await context.read<StreamChatService>().unblockUser(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unblocked ${user.name}')));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _blocked.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  "You haven't blocked anyone.\n\nLong-press a member in a chat's info screen to block them.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
              ),
            )
          : ListView.builder(
              itemCount: _blocked.length,
              itemBuilder: (_, i) {
                final u = _blocked[i];
                return ListTile(
                  leading: UserAvatar(
                    name: u.name,
                    avatarUrl: u.avatarUrl,
                    size: 42,
                  ),
                  title: Text(u.name.isEmpty ? '@${u.id}' : u.name),
                  subtitle: Text('@${u.id}'),
                  trailing: TextButton(
                    onPressed: () => _unblock(u),
                    child: const Text('Unblock'),
                  ),
                );
              },
            ),
    );
  }
}

// ======================= Help & Support =======================
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _openGmailDirectly(BuildContext context) async {
    final subject = Uri.encodeComponent('Stream Chat V1 - Support Ticket');
    final body = Uri.encodeComponent(
      'Hello Support Team,\n\nI am facing the following issue:\n',
    );
    final Uri emailLaunchUri = Uri.parse(
      'mailto:officialomar2004@gmail.com?subject=$subject&body=$body',
    );

    try {
      await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalNonBrowserApplication,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No email app installed on this device to handle this action.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<AppState>().locale == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'المساعدة والدعم' : 'Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(
              Icons.question_answer_outlined,
              color: Colors.blue,
            ),
            title: Text(isArabic ? 'الأسئلة الشائعة (FAQ)' : 'FAQ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FAQScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.mail_outline, color: Colors.orange),
            title: Text(
              isArabic
                  ? 'الإبلاغ عن مشكلة (Gmail)'
                  : 'Report a Problem (Gmail)',
            ),
            trailing: const Icon(Icons.open_in_new, size: 16),
            onTap: () => _openGmailDirectly(context),
          ),
        ],
      ),
    );
  }
}

// ======================= FAQ Screen =======================
class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<AppState>().locale;
    final isArabic = lang == 'ar';

    return Scaffold(
      appBar: AppBar(title: Text(isArabic ? 'الأسئلة الشائعة' : 'FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQTile(
            isArabic
                ? 'كيف يمكنني تعديل بيانات ملفي الشخصي؟'
                : 'How can I edit my profile details?',
            isArabic
                ? 'اضغط على زر "تعديل الحساب" في شاشة الإعدادات. من هناك يمكنك تغيير اسمك الكامل وصورتك الشخصية. لتغيير الصورة، اضغط على الأيقونة داخل شاشة التعديل واختر من المعرض أو التقط صورة جديدة.'
                : 'Tap the "Edit Profile" button on the Settings screen. From there you can update your display name and profile picture. To change your photo, tap the avatar inside the Edit Profile screen and choose from your gallery or take a new one.',
          ),
          _buildFAQTile(
            isArabic
                ? 'هل يدعم التطبيق العمل بدون إنترنت (Offline)؟'
                : 'Does the app work offline?',
            isArabic
                ? 'نعم، يتم حفظ الرسائل والقنوات المحملة سابقاً محلياً ويمكنك تصفحها وقراءتها في أي وقت بدون اتصال بالإنترنت. أما إرسال الرسائل الجديدة فيتطلب اتصالاً نشطاً.'
                : 'Yes! Stream Chat V1 caches previously loaded messages and channels locally so you can browse them without a connection. Sending new messages requires an active internet connection.',
          ),
          _buildFAQTile(
            isArabic
                ? 'كيف يمكنني حذف أو تعديل رسالة تم إرسالها؟'
                : 'How do I delete or edit a sent message?',
            isArabic
                ? 'اضغط مطولاً على أي رسالة أرسلتها، وستظهر قائمة خيارات تتيح لك تعديل النص أو حذف الرسالة نهائياً. لا يمكنك تعديل أو حذف رسائل الآخرين.'
                : 'Long-press on any message you sent. A context menu will appear with options to edit the text or permanently delete the message. You cannot edit or delete other users\' messages.',
          ),
          _buildFAQTile(
            isArabic
                ? 'كيف أنشئ مجموعة جديدة؟'
                : 'How do I create a new group channel?',
            isArabic
                ? 'من شاشة القنوات الرئيسية، اضغط على أيقونة الإضافة (+) في الزاوية العلوية. اختر "مجموعة جديدة"، أضف الأعضاء الذين تريدهم، ثم أدخل اسم المجموعة واضغط إنشاء.'
                : 'From the main Channels screen, tap the compose icon in the top corner. Select "New Group", add the members you want, enter a group name, then tap Create.',
          ),
          _buildFAQTile(
            isArabic
                ? 'كيف أتحكم في تفعيل الإشعارات؟'
                : 'How do I manage push notifications?',
            isArabic
                ? 'من قسم "الإشعارات" داخل الإعدادات، يمكنك تفعيل أو تعطيل إشعارات التطبيق بشكل كامل. الإعداد يُحفظ تلقائياً.'
                : 'Open Settings and go to the "Notifications" section. Toggle the Push Notifications switch on or off. The setting is saved automatically.',
          ),
          _buildFAQTile(
            isArabic
                ? 'كيف يتم تأمين حسابي وبياناتي؟'
                : 'How is my account and data secured?',
            isArabic
                ? 'تتم المصادقة باستخدام JWT Tokens مشفرة ولا يتم تخزين كلمة المرور بنص واضح على الجهاز أو الخوادم. جميع البيانات أثناء النقل مشفرة عبر بروتوكول TLS 1.2+. يمكنك تغيير كلمة المرور أو البريد الإلكتروني في أي وقت من قسم "الحساب والأمان".'
                : 'Authentication uses encrypted JWT tokens and no plaintext password is ever stored on your device or our servers. All data in transit is protected with TLS 1.2+ encryption. You can update your password or email at any time from the "Account & Security" section in Settings.',
          ),
          _buildFAQTile(
            isArabic
                ? 'ما هو الحد الأقصى لحجم المرفقات؟'
                : 'What is the maximum attachment size?',
            isArabic
                ? 'يدعم التطبيق رفع الصور والفيديوهات والمستندات بحد أقصى 20 ميجابايت للملف الواحد. في حال تجاوز الحجم ستظهر رسالة خطأ توضح ذلك.'
                : 'The app supports uploading images, videos, and documents up to 20 MB per file. If a file exceeds the limit, an error message will notify you before sending.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQTile(String title, String content) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              content,
              style: const TextStyle(height: 1.5, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= About & Policies =======================
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Stream Chat V1',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Developed for AASTMT\nCourse: Mobile Application Flutter',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TermsScreen()),
              ),
              child: const Text('Terms of Service'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PolicyScreen()),
              ),
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          "1. Introduction\n"
          "Stream Chat V1 is a mobile messaging application developed as an academic project for the Arab Academy for Science, Technology & Maritime Transport (AASTMT), Mobile Application Development course using Flutter.\n\n"
          "2. Acceptance of Terms\n"
          "By creating an account and using this application, you confirm that you have read, understood, and agree to be bound by these Terms of Service. If you do not agree, please do not use the app.\n\n"
          "3. User Conduct\n"
          "Users are expected to communicate respectfully. The following are strictly prohibited: sending spam or unsolicited messages, uploading inappropriate or offensive content, impersonating other users, and any form of harassment or abuse.\n\n"
          "4. Account Responsibility\n"
          "You are responsible for maintaining the confidentiality of your account credentials. Any activity that occurs under your account is your responsibility. Report unauthorized access immediately via the Help & Support section.\n\n"
          "5. Service Availability\n"
          "The messaging backend is powered by GetStream.io Cloud infrastructure. While the platform targets high availability, brief interruptions may occur. Offline mode allows you to view previously cached messages during downtime.\n\n"
          "6. Content Ownership\n"
          "You retain ownership of any content you post. By using the app, you grant the application a limited, non-exclusive license to display and transmit your content solely for the purpose of providing the messaging service.\n\n"
          "7. Modifications\n"
          "These terms may be updated at any time. Continued use of the application after changes constitutes your acceptance of the updated terms.\n\n"
          "8. Limitation of Liability\n"
          "This is an academic project developed for educational purposes. The developers are not liable for any data loss, service interruptions, or damages arising from the use of this application.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          "1. Data We Collect\n"
          "During registration we collect your display name, username, email address, and an optional profile picture. This information is securely stored on the Stream Chat Cloud backend and is used solely to provide the messaging service.\n\n"
          "2. How Your Data Is Used\n"
          "Your information is used to identify you within the app, display your profile to other users, and deliver messages. We do not sell, rent, or share your personal data with third parties for marketing purposes.\n\n"
          "3. Messaging & Attachments\n"
          "Messages, attachments, reactions, and threads you send are stored on GetStream.io servers. All data in transit is protected using TLS 1.2+ encryption to prevent interception.\n\n"
          "4. Authentication & Passwords\n"
          "Authentication is managed via encrypted JWT tokens. No plaintext passwords are ever stored on your device or on our servers. You can change your password at any time from Account & Security in Settings.\n\n"
          "5. Push Notifications\n"
          "The app may deliver in-app notifications for new messages and @mentions while the app is running. You can disable notifications at any time from the Settings screen.\n\n"
          "6. Local Storage\n"
          "To support offline mode, the app caches recently loaded messages and channel data locally on your device. This data is managed automatically and is cleared when you sign out.\n\n"
          "7. Data Retention\n"
          "Your account data is retained as long as your account is active. You may request deletion of your account and associated data by contacting support through the Help & Support section.\n\n"
          "8. Contact\n"
          "If you have any questions or concerns about this Privacy Policy, please reach out via the Report a Problem option in Help & Support.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
