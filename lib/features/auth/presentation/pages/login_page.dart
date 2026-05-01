import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_animated_container.dart';
import 'register_page.dart';
import 'admin_login_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();

  final List<String> _volumeSequence = [];
  final List<String> _secretSequence = ['down', 'up', 'down', 'down'];
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      if (msg == 'AppLifecycleState.resumed') {
        _volumeSequence.clear();
      }
      return null;
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleVolumeButton(String direction) {
    _volumeSequence.add(direction);
    if (_volumeSequence.length > _secretSequence.length) {
      _volumeSequence.removeAt(0);
    }
    if (_volumeSequence.length == _secretSequence.length) {
      bool matches = true;
      for (int i = 0; i < _secretSequence.length; i++) {
        if (_volumeSequence[i] != _secretSequence[i]) {
          matches = false;
          break;
        }
      }
      if (matches) {
        _volumeSequence.clear();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginPage()),
        );
      }
    }
  }

  String _sanitizeError(String message) {
    final lower = message.toLowerCase();

    // Wrong password / invalid credentials
    if (lower.contains('invalid password')) {
      return 'Wrong password. Please try again.';
    }
    if (lower.contains('invalid credentials')) {
      return 'Invalid phone number or password.';
    }

    // User not found
    if (lower.contains('user not found') || lower.contains('not found')) {
      return 'No account found with this phone number. Please register first.';
    }

    // Password not set
    if (lower.contains('password not set')) {
      return 'Password not set for this account. Please use OTP login.';
    }

    // Invalid or expired OTP
    if (lower.contains('invalid') && lower.contains('otp')) {
      return 'Invalid or expired OTP. Please try again.';
    }

    // No internet / network errors
    if (lower.contains('no internet') ||
        lower.contains('socketexception') ||
        lower.contains('connection refused') ||
        lower.contains('network error')) {
      return 'No internet connection. Please check your network.';
    }

    // Timeout
    if (lower.contains('timeout')) {
      return 'Connection timed out. Please check your internet.';
    }

    // Server errors (500, 502, 503, etc.)
    if (lower.contains('server error') ||
        lower.contains('502') ||
        lower.contains('503')) {
      return 'Server is not responding. Please try again later.';
    }

    // Catch-all for raw technical errors only
    if (lower.contains('dioexception') ||
        lower.contains('handshakeexception') ||
        lower.contains('errno') ||
        lower.contains('type \'') ||
        lower.contains('unexpected character')) {
      return 'Something went wrong. Please try again later.';
    }

    return message;
  }

  void _showErrorDialog(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Error',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(
            opacity: anim1,
            child: AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Login Failed',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _sanitizeError(message),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomButton(
                    text: 'OK',
                    height: 48,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _normalizePhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length >= 12) {
      return '+$digits';
    }
    return '+91$digits';
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            LoginEvent(
              phoneNumber: _normalizePhoneNumber(_phoneController.text.trim()),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
              _handleVolumeButton('down');
            } else if (event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
              _handleVolumeButton('up');
            }
          }
        },
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              Navigator.pushReplacementNamed(context, '/home');
            } else if (state is AuthError) {
              _showErrorDialog(state.message);
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;

            return AuthBackground(
              child: AuthAnimatedContainer(
                logo: _buildLogoSection(isDark),
                form: _buildFormSection(isDark, isLoading),
                bottomContent: _buildBottomLinks(isLoading),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isDark) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.support_agent_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue to Index Care',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white54 : Colors.grey[500],
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildFormSection(bool isDark, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.white,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CustomTextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              label: 'Phone Number',
              hint: '9876543210',
              prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Color(0xFF2563EB)),
              keyboardType: TextInputType.number,
              validator: Validators.validatePhone,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
              prefixText: '+91 ',
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              onFieldSubmitted: (_) {
                _passwordFocus.requestFocus();
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              label: 'Password',
              hint: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_rounded, size: 20, color: Color(0xFF2563EB)),
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ForgotPasswordPage(),
                          ),
                        );
                      },
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Sign In',
              icon: Icons.login_rounded,
              isLoading: isLoading,
              onPressed: _handleLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLinks(bool isLoading) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account? ",
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white54 : Colors.grey[500],
              ),
            ),
            GestureDetector(
              onTap: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                    },
              child: const Text(
                'Register',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminLoginPage()),
          ),
          child: Text(
            'Admin Login',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white38 : Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
