import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/hive_service.dart';
import 'services/firebase_service.dart';
import 'root_decider.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';
import 'ui/theme/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _passwordController.clear();
      _confirmController.clear();
    });
  }

  String? _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty) return 'Email cannot be empty.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Enter a valid email address.';
    }
    if (password.isEmpty) return 'Password cannot be empty.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    if (!_isLogin && password != confirm) return 'Passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      _showError(error);
      return;
    }

    setState(() => _loading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final settings = HiveService.settings;

      if (_isLogin) {
        await FirebaseService.signIn(email, password);
      } else {
        await FirebaseService.signUp(email, password);
      }

      // Persist session locally
      await settings.put('uid', FirebaseService.uid ?? email.toLowerCase());
      await settings.put('isLoggedIn', true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootDecider()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(FirebaseService.friendlyError(e));
    } catch (_) {
      _showError('Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.danger.withValues(alpha: 0.9),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: HolographicPanel(
            header: SystemHeaderBar(
              label: _isLogin ? 'SYSTEM ACCESS' : 'REGISTER OPERATIVE',
            ),
            emphasize: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo + Title ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/app_icon.png',
                      height: 72,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'ARISE OS',
                        style: AppTextStyles.headerMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  _isLogin
                      ? 'Enter your credentials to link with the system.'
                      : 'Create your operative profile.',
                  style: AppTextStyles.bodySecondary,
                ),
                const SizedBox(height: 24),

                // ── Email ──
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, size: 18),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Password ──
                TextField(
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon:
                        const Icon(Icons.lock_outline, size: 18),
                    suffixIcon: GestureDetector(
                      onTap: () =>
                          setState(() => _showPassword = !_showPassword),
                      child: Icon(
                        _showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),

                // ── Confirm Password (Register only) ──
                if (!_isLogin) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmController,
                    obscureText: !_showConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon:
                          const Icon(Icons.lock_outline, size: 18),
                      suffixIcon: GestureDetector(
                        onTap: () =>
                            setState(() => _showConfirm = !_showConfirm),
                        child: Icon(
                          _showConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // ── Primary Button ──
                SizedBox(
                  width: double.infinity,
                  child: _loading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        )
                      : PrimaryActionButton(
                          label: _isLogin
                              ? 'Initialize ARISE OS'
                              : 'Create Account',
                          onPressed: _submit,
                        ),
                ),

                const SizedBox(height: 16),

                // ── Toggle Link ──
                Center(
                  child: GestureDetector(
                    onTap: _loading ? null : _toggleMode,
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySecondary,
                        children: [
                          TextSpan(
                            text: _isLogin
                                ? 'New operative?  '
                                : 'Already registered?  ',
                          ),
                          TextSpan(
                            text: _isLogin ? 'Register' : 'Login',
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
