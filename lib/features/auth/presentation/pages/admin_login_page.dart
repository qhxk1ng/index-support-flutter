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

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }
  
  String _normalizePhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length >= 12) {
      return '+$digits';
    }
    return '+91$digits';
  }

  void _handleAdminLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        AdminLoginEvent(
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
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Admin login successful!'),
                backgroundColor: AppColors.success,
              ),
            );
            
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          } else if (state is AuthError) {
            String errorMsg = state.message;
            final lower = errorMsg.toLowerCase();
            if (lower.contains('invalid credentials')) {
              errorMsg = 'Invalid admin phone number or password.';
            } else if (lower.contains('invalid password')) {
              errorMsg = 'Wrong password. Please try again.';
            } else if (lower.contains('not found')) {
              errorMsg = 'Admin account not found.';
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: AppColors.error,
              ),
            );
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
              colors: [Color(0xFFDC2626), Color(0xFF991B1B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.admin_panel_settings_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Admin Access',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Secure login for administrators',
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
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Restricted to authorized personnel only.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            CustomTextField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              label: 'Admin Phone Number',
              hint: '9876543210',
              prefixIcon: const Icon(Icons.phone_rounded, size: 20, color: Color(0xFFDC2626)),
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
              label: 'Admin Password',
              hint: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_rounded, size: 20, color: Color(0xFFDC2626)),
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
              onFieldSubmitted: (_) => _handleAdminLogin(),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Login as Admin',
              icon: Icons.admin_panel_settings_rounded,
              isLoading: isLoading,
              backgroundColor: const Color(0xFFDC2626),
              onPressed: _handleAdminLogin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomLinks(bool isLoading) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        GestureDetector(
          onTap: isLoading ? null : () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                const SizedBox(width: 8),
                Text(
                  'Back to User Login',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
