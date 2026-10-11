import 'package:flutter/widgets.dart';

class Logo extends StatefulWidget {
  final double size;

  const Logo({super.key, this.size = 100});

  @override
  State<Logo> createState() => _Logo();
}

class _Logo extends State<Logo> with SingleTickerProviderStateMixin {
  late final AnimationController midlineMovement;
  late final Animation<double> height;

  @override
    void initState() {
      super.initState();
      midlineMovement = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 3000),
      )..forward();

      height = TweenSequence<double>([

      TweenSequenceItem(
        tween: Tween<double>(begin: 49, end: 72).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 72, end: 24).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 24, end: 49).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
    ]).animate(midlineMovement);

  }

  @override
  void dispose() {
    midlineMovement.dispose();
    super.dispose(); 
   }

   @override
   Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1118),
        borderRadius: BorderRadius.circular(widget.size * 0.22),
        border: Border.all(color: const Color(0xFF4A9EFF).withValues(alpha: 0.25)), 
      ),

      child: AnimatedBuilder(
        animation: height,
        builder: (context, child) {
          return CustomPaint(
            painter: LogoPaint(position: height.value),
          );
        },
      ),
    );
  }
}

  class LogoPaint extends CustomPainter {
    final double position;

    LogoPaint({required this.position});

    @override
  void paint(Canvas canvas, Size logoSize) {
    final scaleValue = logoSize.width / 100;

    canvas.scale(scaleValue);

    final linePart = Path();
      linePart.moveTo(18, position);
      linePart.lineTo(67, position);

       final whitepaintVal = Paint();
     whitepaintVal.color = const Color(0xFFFFFFFF);
      whitepaintVal.style = PaintingStyle.stroke;
      whitepaintVal.strokeWidth = 3;
      whitepaintVal.strokeCap = StrokeCap.round;
      whitepaintVal.strokeJoin = StrokeJoin.round;

      final whitepaintVal2 = Paint();
     whitepaintVal2.color = const Color(0xFFFFFFFF);
      whitepaintVal2.style = PaintingStyle.stroke;
      whitepaintVal2.strokeWidth = 2.5;
      whitepaintVal2.strokeCap = StrokeCap.round;


    final bluepaintVal = Paint();
     bluepaintVal.color = const Color(0xFF4A9EFF);
     bluepaintVal.style = PaintingStyle.stroke;
      bluepaintVal.strokeWidth = 4;
      bluepaintVal.strokeCap = StrokeCap.round;
      bluepaintVal.strokeJoin = StrokeJoin.round;

      final letterLrepLuma = Path();
      letterLrepLuma.moveTo(18, 49);
      letterLrepLuma.lineTo(18, 76);
      letterLrepLuma.lineTo(37, 76);

    canvas.drawPath(letterLrepLuma, bluepaintVal);

      final docPath = Path();
      docPath.moveTo(28, 15);
      docPath.lineTo(58, 15);
      docPath.lineTo(72, 29);
      docPath.lineTo(72, 78);
      docPath.lineTo(28, 78);
      docPath.close();

      canvas.drawPath(docPath, whitepaintVal);

      canvas.drawLine(const Offset(37, 36), const Offset(63, 36), whitepaintVal2);
      canvas.drawLine(const Offset(37, 58), const Offset(63, 58), whitepaintVal2);
      canvas.drawLine(const Offset(37, 67), const Offset(54, 67), whitepaintVal2);

      final foldCorner = Path();
      foldCorner.moveTo(58, 15);
      foldCorner.lineTo(58, 29);
      foldCorner.lineTo(72, 29);

    canvas.drawPath(foldCorner, bluepaintVal);
    canvas.drawPath(linePart, bluepaintVal);

  }

   @override
  bool shouldRepaint(covariant LogoPaint oldDelegate) {
    return oldDelegate.position != position;
  }
}