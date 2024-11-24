import 'package:flutter/material.dart';

class RadialPageRoute<T> extends PageRoute<T> {
  final Widget child;
  final Duration duration;
  final Alignment center;

  RadialPageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.center = Alignment.center,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return ClipPath(
          clipper: CircularRevealClipper(
            fraction: animation.value,
            center: center,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

class CircularRevealClipper extends CustomClipper<Path> {
  final double fraction;
  final Alignment center;

  CircularRevealClipper({
    required this.fraction,
    this.center = Alignment.center,
  });

  @override
  Path getClip(Size size) {
    final center = this.center.alongSize(size);
    final radius = fraction * size.longestSide;
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.fraction != fraction || oldClipper.center != center;
  }
}
