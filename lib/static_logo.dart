import 'package:flutter/widgets.dart';
import 'package:lumascanner/services/logo.dart';

class StaticLogo extends StatelessWidget {
  final double size;
  const StaticLogo({super.key, this.size = 100});

  @override
   Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
         color: const Color(0xFF0D1118),
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: const Color(0xFF4A9EFF).withValues(alpha: 0.25)),
      ),

      child: CustomPaint(
        painter: LogoPaint(position: 49),
      ),
    );
   }
}