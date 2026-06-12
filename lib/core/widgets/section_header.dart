import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onButtonPressed;
  final String? buttonLabel;
  final IconData? buttonIcon;

  const SectionHeader({
    super.key,
    required this.title,
    this.onButtonPressed,
    this.buttonLabel,
    this.buttonIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: GoogleFonts.dmSans().fontFamily,
          ),
        ),
        if (onButtonPressed != null && buttonLabel != null)
          OutlinedButton.icon(
            onPressed: onButtonPressed,
            icon: buttonIcon != null ? Icon(buttonIcon) : const SizedBox.shrink(),
            label: Text(buttonLabel!),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
      ],
    );
  }
}
