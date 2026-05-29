import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
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

// ---- شاشة تغيير الإيميل باحترافية ----
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
      // ⚠️ مهم: هنا تضع كود Firebase لتغيير الإيميل
      // FirebaseAuth.instance.currentUser!.updateEmail(_emailController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email updated! Please login again.')),
      );
      // يفضل تسجيل خروج المستخدم ليدخل بالإيميل الجديد
      // context.read<AppState>().signOut();
      // context.go('/login');
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

// ---- شاشة تغيير كلمة المرور باحترافية ----
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
      // ⚠️ مهم: هنا تضع كود Firebase لتغيير الباسورد
      // FirebaseAuth.instance.currentUser!.updatePassword(_newPassController.text);

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

// ---- شاشة سجل الدخول (Login History) ----
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.question_answer_outlined),
            title: const Text('FAQ'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FAQScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Report a Problem'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportProblemScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ExpansionTile(
            title: Text('Does the app work offline?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Yes! Stream Chat V1 supports offline mode via local persistence. Previously loaded messages remain accessible without a network connection.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Can I send attachments?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Yes, you can attach and send images, videos, and document files (PDF, DOC, etc.) within any private or group channel.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('How do mentions work?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Type "@" followed by the username in the chat. The user will receive an in-app badge and a push notification via Firebase Cloud Messaging.',
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: Text('Are my messages secure?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Absolutely. All data in transit uses TLS 1.2+ encryption, and authentication is handled securely via JWT tokens.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReportProblemScreen extends StatefulWidget {
  const ReportProblemScreen({super.key});
  @override
  State<ReportProblemScreen> createState() => _ReportProblemScreenState();
}

class _ReportProblemScreenState extends State<ReportProblemScreen> {
  XFile? _screenshot;

  Future<void> _pickScreenshot() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _screenshot = file);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report a Problem')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please describe the issue in detail:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'I am facing an issue with...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Attach Screenshot (Optional):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickScreenshot,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
                child: _screenshot != null
                    ? Image.file(File(_screenshot!.path), fit: BoxFit.cover)
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Tap to add screenshot',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report submitted successfully!'),
                    ),
                  );
                  Navigator.pop(context);
                },
                child: const Text(
                  'Submit Report',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
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
