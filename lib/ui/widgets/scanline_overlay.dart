import 'package:flutter/material.dart';

class ScanlineOverlay extends StatelessWidget {
  const ScanlineOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        IgnorePointer(
          child: CustomPaint(
            size: Size.infinite,
            painter: _ScanlinePainter(),
          ),
        ),
      ],
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0A00FFFF) // Ultra-faint Cyan
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
