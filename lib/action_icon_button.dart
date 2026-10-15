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
    final istapAllowed = onTap != null;
    final iconColor = !istapAllowed ? Colors.white24 : isActive ? const Color(0xFF4A9EFF) : Colors.white;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
         splashFactory: InkRipple.splashFactory,
          splashColor: const Color(0xFF4A9EFF).withValues(alpha: 0.3),
          highlightColor: const Color(0xFF4A9EFF).withValues(alpha: 0.12),
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
                    color: !istapAllowed ? Colors.white24: isActive? const Color(0xFF4A9EFF) : Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ]
            )
          )
      )
    );
  }
}