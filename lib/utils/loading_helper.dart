import 'package:flutter/material.dart';
import '../widgets/loading_screen.dart';

class LoadingHelper {
  static bool _isLoading = false;

  static Future<void> showLoadingScreen(BuildContext context) async {
    if (_isLoading) return; // Prevent multiple loading screens
    _isLoading = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return const PopScope(
          canPop: false,
          child: LoadingScreen(),
        );
      },
    ).then((_) => _isLoading = false);

    await Future.delayed(const Duration(milliseconds: 1500));
  }

  static Future<void> hideLoadingScreen(BuildContext context) async {
    if (!_isLoading) return;
    if (!context.mounted) return;
    
    Navigator.of(context, rootNavigator: true).pop();
    _isLoading = false;
    await Future.delayed(const Duration(milliseconds: 300));
  }

  static Future<T?> withLoadingScreen<T>(
    BuildContext context,
    Future<T> Function() task,
  ) async {
    try {
      await showLoadingScreen(context);
      final result = await task();
      if (context.mounted) {
        await hideLoadingScreen(context);
      }
      return result;
    } catch (e) {
      if (context.mounted) {
        await hideLoadingScreen(context);
      }
      rethrow;
    }
  }

  // Helper method for navigation with loading
  static Future<void> navigate(
    BuildContext context,
    String route, {
    bool replacement = false,
  }) async {
    await withLoadingScreen(context, () async {
      await Future.delayed(const Duration(milliseconds: 1000));
      if (context.mounted) {
        if (replacement) {
          await Navigator.pushReplacementNamed(context, route);
        } else {
          await Navigator.pushNamed(context, route);
        }
      }
    });
  }
} 