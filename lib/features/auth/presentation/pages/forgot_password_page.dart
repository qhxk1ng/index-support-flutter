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
import 'otp_verification_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length >= 12) {
      return '+$digits';
    }
    return '+91$digits';
  }

  void _handleSendOtp() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SendOtpEvent(
          phoneNumber: _normalizePhoneNumber(_phoneController.text.trim()),
          type: 'PASSWORD_RESET',
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
          if (state is OtpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent to your phone!'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => OtpVerificationPage(
                  phoneNumber: _normalizePhoneNumber(_phoneController.text.trim()),
                  userId: state.userId,
                  otpType: 'PASSWORD_RESET',
                ),
              ),
            );
          } else if (state is AuthError) {
            String errorMsg = state.message;
            final lower = errorMsg.toLowerCase();
            if (lower.contains('not found')) {
              errorMsg = 'No account found with this phone number.';
            } else if (lower.contains('otp') && lower.contains('fail')) {
              errorMsg = 'Failed to send OTP. Please try again.';
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
            Icons.lock_reset_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your registered phone number.',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white54 : Colors.grey[500],
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
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
              label: 'Phone Number',
              hint: '9876543210',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.phone_rounded),
              prefixText: '+91 ',
              validator: Validators.validatePhone,
              enabled: !isLoading,
              maxLength: 10,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSendOtp(),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Send OTP',
              icon: Icons.sms_rounded,
              isLoading: isLoading,
              onPressed: _handleSendOtp,
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
                  'Back to Login',
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
