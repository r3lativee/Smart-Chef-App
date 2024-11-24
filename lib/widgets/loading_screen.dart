import 'package:flutter/material.dart';
import 'dart:math' as math;

class LoadingScreen extends StatefulWidget {
  final List<dynamic>? recipes;
  const LoadingScreen({super.key, this.recipes});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int currentImageIndex = 0;
  final List<String> loadingImages = [
    'assets/svgs/1.png',
    'assets/svgs/2.png',
    'assets/svgs/3.png',
  ];

  List<dynamic> sortRecipes(List<dynamic> recipes) {
    return [...recipes]..sort((a, b) {
        bool aHasImage = a['image'] != null && a['image'].toString().isNotEmpty;
        bool bHasImage = b['image'] != null && b['image'].toString().isNotEmpty;

        if (aHasImage && !bHasImage) return -1;
        if (!aHasImage && bHasImage) return 1;
        return 0;
      });
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    if (widget.recipes != null) {
      sortRecipes(widget.recipes!);
    }

    Future.delayed(Duration.zero, () {
      _startImageCycling();
    });
  }

  void _startImageCycling() {
    Future.forEach<int>(
      List.generate(loadingImages.length, (index) => index),
      (index) async {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() {
            currentImageIndex = index;
          });
        }
        return index;
      },
    ).then((_) {
      if (mounted) _startImageCycling();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final gradientColors = [
              Colors.purple,
              Colors.blue,
              Colors.green,
              Colors.yellow,
              Colors.orange,
              Colors.red,
              Colors.purple,
            ];

            return Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: SweepGradient(
                  colors: gradientColors,
                  stops: List.generate(
                    gradientColors.length,
                    (index) => index / (gradientColors.length - 1),
                  ),
                  transform: GradientRotation(_controller.value * 2 * math.pi),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: animation,
                              child: child,
                            ),
                          );
                        },
                        child: Hero(
                          key: ValueKey<int>(currentImageIndex),
                          tag: 'chef_image',
                          child: Container(
                            height: 60,
                            width: 60,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                            ),
                            child: Image.asset(
                              loadingImages[currentImageIndex],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return const Icon(
                                  Icons.restaurant_menu,
                                  size: 30,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: child,
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.zero,
                              child: const Text(
                                'Finding Delicious',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.0,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: child,
                              );
                            },
                            child: Container(
                              margin: EdgeInsets.zero,
                              child: const Text(
                                'Recipes',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.0,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
