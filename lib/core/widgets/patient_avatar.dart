import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PatientAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final Color bgColor;

  const PatientAvatar({
    super.key,
    required this.initials,
    this.size = 40,
    this.bgColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
