import 'package:flutter/material.dart';

class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final tapAllowed = onTap != null;
    final iconColor = !tapAllowed
        ? Colors.white24
        : isActive
            ? const Color(0xFF4A9EFF)
            : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: !tapAllowed
                    ? Colors.white24
                    : isActive
                        ? const Color(0xFF4A9EFF)
                        : Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}