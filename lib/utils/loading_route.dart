import 'package:flutter/material.dart';
import 'loading_screen.dart';

class LoadingRoute extends PageRouteBuilder {
  final Widget page;

  LoadingRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOutCubic;

            var fadeAnimation = Tween(
              begin: begin,
              end: end,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: curve,
            ));

            return Stack(
              children: [
                FadeTransition(
                  opacity: fadeAnimation,
                  child: child,
                ),
                FadeTransition(
                  opacity: Tween<double>(
                    begin: 1.0,
                    end: 0.0,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve:
                        const Interval(0.6, 1.0, curve: Curves.easeInOutCubic),
                  )),
                  child: const LoadingScreen(),
                ),
              ],
            );
          },
          transitionDuration: const Duration(milliseconds: 1500),
          reverseTransitionDuration: const Duration(milliseconds: 1500),
        );
}

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: const LoadingScreen(),
          ),
      ],
    );
  }
}
