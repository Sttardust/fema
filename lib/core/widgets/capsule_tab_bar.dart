import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CapsuleTabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const CapsuleTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class CapsuleTabBar extends StatelessWidget {
  final List<CapsuleTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CapsuleTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isActive = index == currentIndex;

              final itemWidget = Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primarySoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isActive ? item.activeIcon : item.icon,
                          size: 22,
                          color: isActive ? AppColors.primary : AppColors.grey,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.label,
                          style: GoogleFonts.figtree(
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                            color: isActive ? AppColors.primary : AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              return itemWidget;
            }),
          ),
        ),
      ),
    );
  }
}
