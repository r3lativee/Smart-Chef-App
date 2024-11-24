import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:smart_chef_app/auth/pages/login_page.dart';
import 'package:smart_chef_app/auth/pages/register_page.dart';
import 'package:smart_chef_app/screens/home.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'auth/auth_wrapper.dart';

Future<FirebaseApp> initializeFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) {
      print('Using existing Firebase instance');
      return Firebase.app();
    }

    print('Creating new Firebase instance');
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    if (e is FirebaseException && e.code == 'duplicate-app') {
      print('Using existing Firebase instance after error');
      return Firebase.app();
    }
    print('Firebase initialization error: $e');
    rethrow;
  }
}

Future<void> setupApp() async {
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  if (Platform.isAndroid) {
    await SystemChannels.platform
        .invokeMethod('SystemChrome.setPreferredRefreshRate', 120);
  }
}

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize or get existing Firebase instance
    FirebaseApp firebaseApp;
    try {
      firebaseApp = await initializeFirebase();
    } catch (e) {
      if (e is FirebaseException && e.code == 'duplicate-app') {
        firebaseApp = Firebase.app();
      } else {
        rethrow;
      }
    }
    print('Firebase app name: ${firebaseApp.name}');

    // Setup app preferences
    await setupApp();

    // Get SharedPreferences instance
    final prefs = await SharedPreferences.getInstance();

    // Create AuthService after Firebase is initialized
    final authService = AuthService(prefs);

    // Run the app with Provider
    runApp(
      Provider<AuthService>.value(
        value: authService,
        child: const SmartChefApp(),
      ),
    );
  } catch (e, stackTrace) {
    print('Error initializing app: $e');
    print('Stack trace: $stackTrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

class SmartChefApp extends StatelessWidget {
  const SmartChefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Chef',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CustomPageTransitionBuilder(),
            TargetPlatform.iOS: CustomPageTransitionBuilder(),
          },
        ),
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}

class CustomPageTransitionBuilder extends PageTransitionsBuilder {
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.0, 0.9),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      ),
    );
  }
}
