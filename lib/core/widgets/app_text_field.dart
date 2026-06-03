import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final TextEditingController? controller;
  final String icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final String? errorText;

  const AppTextField({
    Key? key,
    required this.label,
    this.hintText,
    this.controller,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.hasError = false,
    this.errorText,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onChanged: widget.onChanged,
      style: TextStyle(
        fontSize: 14,
        fontFamily: GoogleFonts.dmSans().fontFamily,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        label: Text(widget.label),
        hintText: widget.hintText,
        errorText: widget.errorText,
        enabledBorder: widget.hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.danger),
              )
            : null,
        focusedBorder: widget.hasError
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.danger, width: 2),
              )
            : null,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 8),
          child: Text(widget.icon, style: const TextStyle(fontSize: 18)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: widget.obscureText
            ? GestureDetector(
                onTap: () => setState(() => _obscureText = !_obscureText),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    _obscureText ? '👁' : '👁‍🗨',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
