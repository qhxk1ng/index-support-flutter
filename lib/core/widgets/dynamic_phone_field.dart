import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class CountryInfo {
  final String name;
  final String dialCode;
  final String code;
  final String flag;
  final int maxLength;
  final String hint;

  const CountryInfo({
    required this.name,
    required this.dialCode,
    required this.code,
    required this.flag,
    this.maxLength = 10,
    this.hint = '98765 43210',
  });
}

class DynamicPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final bool enabled;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final void Function(String)? onChanged;
  final void Function(CountryInfo)? onCountryChanged;
  final String? Function(String?)? validator;
  final String initialDialCode;

  const DynamicPhoneField({
    super.key,
    required this.controller,
    this.focusNode,
    this.label = 'Phone Number',
    this.enabled = true,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.onChanged,
    this.onCountryChanged,
    this.validator,
    this.initialDialCode = '+91',
  });

  /// Standard curated list of supported countries
  static const List<CountryInfo> supportedCountries = [
    CountryInfo(name: 'India', dialCode: '+91', code: 'IN', flag: '🇮🇳', maxLength: 10, hint: '98765 43210'),
    CountryInfo(name: 'United States', dialCode: '+1', code: 'US', flag: '🇺🇸', maxLength: 10, hint: '202 555 0123'),
    CountryInfo(name: 'United Kingdom', dialCode: '+44', code: 'GB', flag: '🇬🇧', maxLength: 10, hint: '7911 123456'),
    CountryInfo(name: 'United Arab Emirates', dialCode: '+971', code: 'AE', flag: '🇦🇪', maxLength: 9, hint: '50 123 4567'),
    CountryInfo(name: 'Saudi Arabia', dialCode: '+966', code: 'SA', flag: '🇸🇦', maxLength: 9, hint: '50 123 4567'),
    CountryInfo(name: 'Canada', dialCode: '+1', code: 'CA', flag: '🇨🇦', maxLength: 10, hint: '416 555 0123'),
    CountryInfo(name: 'Australia', dialCode: '+61', code: 'AU', flag: '🇦🇺', maxLength: 9, hint: '412 345 678'),
    CountryInfo(name: 'Singapore', dialCode: '+65', code: 'SG', flag: '🇸🇬', maxLength: 8, hint: '8123 4567'),
    CountryInfo(name: 'Germany', dialCode: '+49', code: 'DE', flag: '🇩🇪', maxLength: 11, hint: '151 23456789'),
    CountryInfo(name: 'France', dialCode: '+33', code: 'FR', flag: '🇫🇷', maxLength: 9, hint: '6 12 34 56 78'),
    CountryInfo(name: 'Qatar', dialCode: '+974', code: 'QA', flag: '🇶🇦', maxLength: 8, hint: '3312 3456'),
    CountryInfo(name: 'Kuwait', dialCode: '+965', code: 'KW', flag: '🇰🇼', maxLength: 8, hint: '9123 4567'),
    CountryInfo(name: 'Oman', dialCode: '+968', code: 'OM', flag: '🇴🇲', maxLength: 8, hint: '9123 4567'),
    CountryInfo(name: 'Nepal', dialCode: '+977', code: 'NP', flag: '🇳🇵', maxLength: 10, hint: '9841 234567'),
    CountryInfo(name: 'Bangladesh', dialCode: '+880', code: 'BD', flag: '🇧🇩', maxLength: 10, hint: '1712 345678'),
    CountryInfo(name: 'Sri Lanka', dialCode: '+94', code: 'LK', flag: '🇱🇰', maxLength: 9, hint: '71 234 5678'),
    CountryInfo(name: 'Malaysia', dialCode: '+60', code: 'MY', flag: '🇲🇾', maxLength: 10, hint: '12 345 6789'),
    CountryInfo(name: 'Other (International)', dialCode: '+', code: 'INT', flag: '🌐', maxLength: 15, hint: 'Phone number'),
  ];

  static CountryInfo getCountryByDialCode(String dialCode) {
    return supportedCountries.firstWhere(
      (c) => c.dialCode == dialCode,
      orElse: () => supportedCountries.first,
    );
  }

  @override
  State<DynamicPhoneField> createState() => DynamicPhoneFieldState();
}

class DynamicPhoneFieldState extends State<DynamicPhoneField> {
  late CountryInfo _selectedCountry;

  CountryInfo get selectedCountry => _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry = DynamicPhoneField.getCountryByDialCode(widget.initialDialCode);
    widget.controller.addListener(_handleTextChanges);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanges);
    super.dispose();
  }

  /// Automatically inspects input for pasted full phone numbers (e.g., "+919876543210" or "919876543210")
  void _handleTextChanges() {
    final text = widget.controller.text;
    if (text.isEmpty) return;

    // Check if pasted number starts with '+'
    if (text.startsWith('+')) {
      for (final country in DynamicPhoneField.supportedCountries) {
        if (country.dialCode != '+' && text.startsWith(country.dialCode)) {
          final remainder = text.substring(country.dialCode.length).replaceAll(RegExp(r'\D'), '');
          if (_selectedCountry != country) {
            setState(() {
              _selectedCountry = country;
            });
            widget.onCountryChanged?.call(country);
          }
          if (widget.controller.text != remainder) {
            widget.controller.value = TextEditingValue(
              text: remainder,
              selection: TextSelection.collapsed(offset: remainder.length),
            );
          }
          return;
        }
      }
    }

    // Check if Indian number pasted with '91' prefix (12 digits)
    if (_selectedCountry.dialCode == '+91' && text.length > 10 && text.startsWith('91')) {
      final sanitized = text.substring(2);
      if (sanitized.length <= 10) {
        widget.controller.value = TextEditingValue(
          text: sanitized,
          selection: TextSelection.collapsed(offset: sanitized.length),
        );
        return;
      }
    }

    // Check if pasted with leading 0 (e.g. 09876543210)
    if (_selectedCountry.dialCode == '+91' && text.length == 11 && text.startsWith('0')) {
      final sanitized = text.substring(1);
      widget.controller.value = TextEditingValue(
        text: sanitized,
        selection: TextSelection.collapsed(offset: sanitized.length),
      );
      return;
    }
  }

  /// Returns clean E.164 phone string (e.g. "+919876543210")
  String getNormalizedPhoneNumber() {
    final digits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    final dial = _selectedCountry.dialCode.replaceAll('+', '');
    if (dial.isEmpty) {
      return digits.startsWith('+') ? digits : '+$digits';
    }
    return '+$dial$digits';
  }

  /// Returns clean mobile digits without country code
  String getRawPhoneNumber() {
    return widget.controller.text.replaceAll(RegExp(r'\D'), '');
  }

  void _showCountryPicker() {
    if (!widget.enabled) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CountryPickerBottomSheet(
        selectedCountry: _selectedCountry,
        onSelect: (country) {
          setState(() {
            _selectedCountry = country;
          });
          widget.onCountryChanged?.call(country);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.phone,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      onChanged: widget.onChanged,
      maxLength: _selectedCountry.maxLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
      ],
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
      ),
      validator: widget.validator ??
          (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Phone number is required';
            }
            final digits = val.replaceAll(RegExp(r'\D'), '');
            if (_selectedCountry.dialCode == '+91') {
              if (digits.length != 10) {
                return 'Please enter a valid 10-digit mobile number';
              }
            } else {
              if (digits.length < 6 || digits.length > 15) {
                return 'Please enter a valid phone number';
              }
            }
            return null;
          },
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: _selectedCountry.hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.white38 : Colors.grey[400],
          fontSize: 14,
        ),
        labelStyle: TextStyle(
          color: isDark ? Colors.white54 : Colors.grey[500],
          fontSize: 14,
        ),
        counterText: '',
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _showCountryPicker,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry.dialCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: isDark ? Colors.white54 : Colors.grey[600],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 24,
                width: 1.2,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: isDark ? const Color(0xFF334155) : Colors.grey[300],
              ),
            ],
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF334155) : Colors.grey[200]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

class _CountryPickerBottomSheet extends StatefulWidget {
  final CountryInfo selectedCountry;
  final ValueChanged<CountryInfo> onSelect;

  const _CountryPickerBottomSheet({
    required this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<_CountryPickerBottomSheet> createState() => _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<_CountryPickerBottomSheet> {
  final _searchController = TextEditingController();
  List<CountryInfo> _filteredCountries = DynamicPhoneField.supportedCountries;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = DynamicPhoneField.supportedCountries;
      } else {
        _filteredCountries = DynamicPhoneField.supportedCountries.where((c) {
          return c.name.toLowerCase().contains(query) ||
              c.dialCode.toLowerCase().contains(query) ||
              c.code.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Text(
                  'Select Country / Dial Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'Search country or code...',
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : Colors.grey[400],
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: _filteredCountries.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : Colors.grey[100],
              ),
              itemBuilder: (ctx, idx) {
                final country = _filteredCountries[idx];
                final isSelected = country.dialCode == widget.selectedCountry.dialCode &&
                    country.code == widget.selectedCountry.code;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        country.dialCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.grey[600]),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
                      ],
                    ],
                  ),
                  onTap: () {
                    widget.onSelect(country);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
