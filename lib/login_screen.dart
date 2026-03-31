import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'root_decider.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
  // 🔹 Example: perform your validation here
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isNotEmpty && password.isNotEmpty) {
    // ✅ After successful validation, mark user as logged in
    final settings = HiveService.settings;
    await settings.put('isLoggedIn', true);

    // 🔹 Navigate to RootDecider
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => RootDecider()),
    );
  } else {
    // Optional: show error if login fails
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid email or password')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: HolographicPanel(
            header: const SystemHeaderBar(label: 'SYSTEM ACCESS'),
            emphasize: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/app_icon.png',
                      height: 72,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'ARISE OS',
                      style: AppTextStyles.headerMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Enter your credentials to link with the system.',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryActionButton(
                    label: 'Initialize ARISE OS',
                    onPressed: _login,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
