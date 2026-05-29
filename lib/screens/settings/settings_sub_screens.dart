import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // 🛠️ الـ import المطلوب لتشغيل فتح الروابط والإيميل
import '../../theme/app_theme.dart';
import '../../providers/app_state.dart';

// ======================= Account & Security =======================
class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account & Security')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Change Email'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangeEmailScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Login History'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginHistoryScreen()),
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated! Please login again.')),
      );
      Navigator.pop(context);
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
                  onPressed: _submit,
                  child: const Text('Update Email'),
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
      Navigator.pop(context);
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
                  onPressed: _submit,
                  child: const Text('Update Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginHistoryScreen extends StatelessWidget {
  const LoginHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login History')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(
            leading: Icon(Icons.phone_android, color: Colors.blue),
            title: Text('iPhone 13 - Cairo, Egypt'),
            subtitle: Text('Today, 10:30 AM'),
            trailing: Text(
              'Current',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.computer),
            title: Text('Windows Chrome - Alexandria, Egypt'),
            subtitle: Text('Yesterday, 08:15 PM'),
          ),
        ],
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
  bool _profileVisibility = false;
  bool _readReceipts = true;

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
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _profileVisibility = val),
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.mark_chat_read),
            title: const Text('Read Receipts'),
            subtitle: const Text(
              'Let others know when you read their messages',
            ),
            value: _readReceipts,
            activeColor: AppColors.primary,
            onChanged: (val) => setState(() => _readReceipts = val),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.red),
            title: const Text('Blocked Users'),
            trailing: const Text(
              '2',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked Users')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Spammer User 1'),
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Unblock'),
            ),
          ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: const Text('Annoying User 2'),
            trailing: TextButton(
              onPressed: () {},
              child: const Text('Unblock'),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= Help & Support =======================
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // 🛠️ الميثود المسؤولة عن فتح الـ Gmail مباشرة بالبيانات المحددة
  Future<void> _openGmailDirectly(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'officalomar2004@gmail.com',
      queryParameters: {
        'subject': 'Stream Chat V1 - Support Ticket',
        'body': 'Hello Support Team,\n\nI am facing the following issue:\n',
      },
    );

    try {
      // بنجبر الـ url_launcher يفتح التطبيق الخارجي مباشرة
      await launchUrl(
        emailLaunchUri,
        mode: LaunchMode
            .externalNonBrowserApplication, // أضمن للـ mailto على أندرويد
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
            onTap: () =>
                _openGmailDirectly(context), // فتح الجيميل مباشرة عند الضغط
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
                ? 'يمكنك الضغط على زر "تعديل الحساب" في الشاشة الرئيسية للإعدادات لتغيير الاسم الكامل أو الصورة الشخصية.'
                : 'You can tap the "Edit Profile" button on the main settings screen to change your full name or profile picture.',
          ),
          _buildFAQTile(
            isArabic
                ? 'هل يدعم التطبيق العمل بدون إنترنت (Offline)؟'
                : 'Does the app work offline?',
            isArabic
                ? 'نعم، يتم حفظ الرسائل والقنوات المحملة سابقاً محلياً ويمكنك تصفحها وقراءتها في أي وقت بدون اتصال.'
                : 'Yes! Stream Chat V1 supports offline mode via local persistence. Previously loaded messages and channels remain accessible.',
          ),
          _buildFAQTile(
            isArabic
                ? 'كيف يمكنني حذف أو تعديل رسالة تم إرسالها؟'
                : 'How do I delete or edit a sent message?',
            isArabic
                ? 'قم بالضغط مطولاً على الرسالة التي قمت بإرسالها، وستظهر لك قائمة خيارات تتيح لك تعديل النص أو حذف الرسالة نهائياً.'
                : 'Long-press on any message you sent, and a context menu will appear allowing you to either edit the text or delete the message entirely.',
          ),
          _buildFAQTile(
            isArabic
                ? 'ما هو الحد الأقصى لحجم المرفقات؟'
                : 'What is the maximum file size for attachments?',
            isArabic
                ? 'يدعم التطبيق رفع الصور والفيديوهات والمستندات بحد أقصى 20 ميجابايت للملف الواحد لضمان سرعة الإرسال.'
                : 'The application supports uploading images, videos, and documents up to 20MB per file to ensure optimal transmission speeds.',
          ),
          _buildFAQTile(
            isArabic
                ? 'كيف أتحكم في تفعيل الإشعارات؟'
                : 'How do I manage push notifications?',
            isArabic
                ? 'من قسم "الإشعارات" داخل الإعدادات، يمكنك تفعيل أو تعطيل إشعارات التطبيق العامة أو إشعارات الإشارات (Mentions) بشكل مستقل.'
                : 'From the "Notifications" section inside Settings, you can independently toggle global push notifications or specific @mention alerts.',
          ),
          _buildFAQTile(
            isArabic
                ? 'كيف يتم تأمين حسابي وبياناتي؟'
                : 'How is my account security handled?',
            isArabic
                ? 'تتم عملية المصادقة وتأمين الجلسات بالكامل باستخدام الـ JWT Tokens المشفرة، كما أن جميع الاتصالات مشفرة عبر بروتوكول TLS 1.2+.'
                : 'Authentication is handled securely via encrypted JWT tokens, and all data in transit is fully protected using TLS 1.2+ encryption standards.',
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
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
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
                color: Colors.blue.withOpacity(0.1),
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
          "1. Introduction\nStream Chat V1 is a mobile messaging application built for the Arab Academy for Science, Technology & Maritime Transport (AASTMT).\n\n"
          "2. Usage Rules\nBy using this application, you agree to respect other users. Spam, abuse, and inappropriate attachments are strictly prohibited.\n\n"
          "3. Service Availability\nThe backend is powered by GetStream.io Cloud. While it provides a 99.999% uptime SLA, brief outages may occur. Offline mode allows you to view cached messages.\n\n"
          "4. Liability\nThis is an academic project. The developers are not liable for any data loss or service interruptions.",
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
          "1. Data Collection\nWe collect your display name, email, and optional profile picture during registration. This data is securely stored on the Stream Chat Cloud backend.\n\n"
          "2. Messaging Privacy\nYour messages, attachments, and threads are stored on GetStream.io servers. All data in transit uses TLS 1.2+ encryption.\n\n"
          "3. Authentication\nAuthentication is handled securely via JWT tokens. No plaintext passwords are ever stored on your device or our servers.\n\n"
          "4. Push Notifications\nWe use Firebase Cloud Messaging (FCM) to deliver push notifications for new messages and @mentions.",
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }
}
