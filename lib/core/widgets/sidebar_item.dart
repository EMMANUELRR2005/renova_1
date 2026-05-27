import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class SidebarItem extends StatelessWidget {
  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const SidebarItem({
    Key? key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border(
                  left: BorderSide(
                    color: const Color(0xFF64B5F6),
                    width: 3,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 20,
                color: isActive ? Colors.white : AppColors.textTertiary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : AppColors.textTertiary,
                fontFamily: GoogleFonts.dmSans().fontFamily,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
