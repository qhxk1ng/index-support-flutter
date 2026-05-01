import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_animated_container.dart';
import 'login_page.dart';
import 'set_password_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber;
  final String? userId;
  final String? password;
  final String otpType;
  
  const OtpVerificationPage({
    super.key,
    required this.phoneNumber,
    this.userId,
    this.password,
    this.otpType = 'REGISTRATION',
  });
  
  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  
  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
  
  void _handleVerifyOtp() {
    if (_formKey.currentState!.validate()) {
      if (widget.userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID is missing. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      final String type = widget.otpType;
      
      context.read<AuthBloc>().add(
        VerifyOtpEvent(
          userId: widget.userId!,
          otp: _otpController.text.trim(),
          type: type,
        ),
      );
    }
  }
  
  void _handleResendOtp() {
    final String type = widget.otpType;
    
    context.read<AuthBloc>().add(
      SendOtpEvent(
        phoneNumber: widget.phoneNumber,
        type: type,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is OtpVerified) {
            if (widget.password != null && widget.password!.isNotEmpty && widget.userId != null) {
              // Registration flow: auto-set password then go to login
              context.read<AuthBloc>().add(
                SetPasswordEvent(
                  userId: widget.userId!,
                  password: widget.password!,
                ),
              );
            } else if (widget.userId != null) {
              // Forgot password flow: go to set password page
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SetPasswordPage(
                    userId: widget.userId!,
                    phoneNumber: widget.phoneNumber,
                  ),
                ),
              );
            } else {
              Navigator.pop(context);
            }
          } else if (state is PasswordSet) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully! Please login.'),
                backgroundColor: AppColors.success,
              ),
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          } else if (state is OtpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('OTP sent successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is AuthError) {
            String errorMsg = state.message;
            final lower = errorMsg.toLowerCase();
            if (lower.contains('invalid') && lower.contains('otp')) {
              errorMsg = 'Invalid or expired OTP. Please try again.';
            } else if (lower.contains('not found')) {
              errorMsg = 'No valid OTP found. Please request a new one.';
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
            Icons.message_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Verify Your Number',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to\n${widget.phoneNumber}',
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
              controller: _otpController,
              label: 'OTP Code',
              hint: '123456',
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.pin_outlined),
              validator: Validators.validateOTP,
              enabled: !isLoading,
              maxLength: 6,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleVerifyOtp(),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Verify OTP',
              onPressed: _handleVerifyOtp,
              isLoading: isLoading,
              icon: Icons.check_circle_outline_rounded,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive the code? ",
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: isLoading ? null : _handleResendOtp,
              child: const Text(
                'Resend',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}
