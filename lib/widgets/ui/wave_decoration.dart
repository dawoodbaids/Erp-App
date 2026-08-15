import 'package:flutter/material.dart';

/// A restrained wave shape for hero sections and empty-state accents.
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 24);
    path.cubicTo(
      size.width * .22,
      size.height - 4,
      size.width * .42,
      size.height - 42,
      size.width * .64,
      size.height - 18,
    );
    path.cubicTo(
      size.width * .82,
      size.height + 2,
      size.width * .93,
      size.height - 18,
      size.width,
      size.height - 34,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class WaveAccent extends StatelessWidget {
  final double height;
  final Color? color;

  const WaveAccent({super.key, this.height = 48, this.color});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: WaveClipper(),
      child: Container(
        height: height,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
