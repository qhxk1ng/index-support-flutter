import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_animated_container.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  
  String _selectedRole = 'CUSTOMER';
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;
  
  final List<Map<String, String>> _roles = [
    {'value': 'CUSTOMER', 'label': 'Customer', 'icon': '👤'},
    {'value': 'FIELD_PERSONNEL', 'label': 'Field Personnel', 'icon': '🚗'},
    {'value': 'SALES_PERSONNEL', 'label': 'Sales Personnel', 'icon': '💼'},
  ];
  
  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isLoadingLocation = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled. Please enable them in settings.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isLoadingLocation = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: AppColors.error,
              ),
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isLoadingLocation = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied. Please enable them in app settings.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get location: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  String _normalizePhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length >= 12) {
      return '+$digits';
    }
    return '+91$digits';
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      if (_latitude == null || _longitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please capture your location'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      
      context.read<AuthBloc>().add(
        RegisterEvent(
          phoneNumber: _normalizePhoneNumber(_phoneController.text.trim()),
          name: _nameController.text.trim(),
          email: '',
          role: _selectedRole,
          latitude: _latitude!,
          longitude: _longitude!,
          address: _addressController.text.trim(),
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
          if (state is RegistrationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful! OTP sent to your phone and email.'),
                backgroundColor: AppColors.success,
              ),
            );
            
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OtpVerificationPage(
                  phoneNumber: _normalizePhoneNumber(_phoneController.text.trim()),
                  userId: state.userId,
                  password: _passwordController.text,
                ),
              ),
            );
          } else if (state is AuthError) {
            String errorMsg = state.message;
            final lower = errorMsg.toLowerCase();
            if (lower.contains('already registered')) {
              errorMsg = 'This phone number is already registered. Please login instead.';
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
            Icons.person_add_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Join Index Care',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create your account to get started',
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
              controller: _nameController,
              label: 'Full Name',
              hint: 'John Doe',
              keyboardType: TextInputType.name,
              prefixIcon: const Icon(Icons.person_outline_rounded),
              validator: Validators.validateName,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
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
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            Text(
              'Select Your Role',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
                ),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _roles.length,
                separatorBuilder: (_, __) => Divider(
                  color: isDark ? const Color(0xFF334155) : Colors.grey[200],
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  final isSelected = _selectedRole == role['value'];
                  
                  return RadioListTile<String>(
                    title: Row(
                      children: [
                        Text(role['icon']!, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Text(
                          role['label']!,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    value: role['value']!,
                    groupValue: _selectedRole,
                    activeColor: const Color(0xFF2563EB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    onChanged: isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A8A).withOpacity(0.2) : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E3A8A) : const Color(0xFFBFDBFE),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location Setup',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_latitude != null && _longitude != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B).withOpacity(0.3) : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Location captured successfully',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoadingLocation || isLoading ? null : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location_rounded, size: 18),
                        label: Text(_isLoadingLocation ? 'Getting Location...' : 'Capture Current Location'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _addressController,
              label: 'Full Address',
              hint: 'Enter your complete address',
              maxLines: 3,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.home_work_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Address is required';
                }
                return null;
              },
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _passwordController,
              label: 'Password',
              hint: 'Create a strong password',
              obscureText: _obscurePassword,
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: Validators.validatePassword,
              enabled: !isLoading,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              obscureText: _obscureConfirmPassword,
              prefixIcon: const Icon(Icons.lock_reset_outlined),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: isDark ? Colors.white38 : Colors.grey[400],
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
              enabled: !isLoading,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleRegister(),
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Create Account',
              onPressed: _handleRegister,
              isLoading: isLoading,
              icon: Icons.person_add_rounded,
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
              'Already have an account? ',
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            GestureDetector(
              onTap: isLoading ? null : () => Navigator.pop(context),
              child: const Text(
                'Log In',
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
