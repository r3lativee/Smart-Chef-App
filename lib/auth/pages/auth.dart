import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  late final AuthService _authService;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeAuthService();
  }

  Future<void> _initializeAuthService() async {
    final prefs = await SharedPreferences.getInstance();
    _authService = AuthService(prefs);
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (mounted) {
        print('Successfully signed in with Google');
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (error) {
      print('Error during Google Sign In: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${error.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            // Logo and text aligned to left
            const Padding(
              padding: EdgeInsets.only(left: 20.0),
              child: Row(
                children: [
                  Icon(
                    Icons.food_bank,
                    size: 40,
                    color: Colors.white,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Smart Chef',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Center the rest of the content
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 5),
                  // Chef Image
                  Hero(
                    tag: 'chef_image',
                    child: Image.asset(
                      'assets/images/chef.png',
                      height: 500,
                      width: 500,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person_outline,
                          size: 200,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                  const Hero(
                    tag: 'app_title',
                    child: Material(
                      color: Colors.transparent,
                      child: Text(
                        'Smart Chef',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Your personal AI-powered cooking assistant. Get recipes, cooking tips, and meal planning help instantly. If you want to learn more about the project, please visit the website. ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 70),
                  // Custom Toggle for Login and Signup
                  Hero(
                    tag: 'auth_toggle',
                    child: Container(
                      width: MediaQuery.of(context).size.width - 90,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isLogin = true;
                                });
                                Navigator.pushNamed(context, '/login');
                              },
                              child: Container(
                                width:
                                    (MediaQuery.of(context).size.width - 90) /
                                        2,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: isLogin
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.login,
                                      color:
                                          isLogin ? Colors.black : Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: isLogin
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isLogin = false;
                                });
                                Navigator.pushNamed(context, '/register');
                              },
                              child: Container(
                                width:
                                    (MediaQuery.of(context).size.width - 90) /
                                        2,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: !isLogin
                                      ? Colors.white
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_add,
                                      color: !isLogin
                                          ? Colors.black
                                          : Colors.white,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: !isLogin
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Google Sign In Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: Image.asset(
                      'assets/images/google_logo.png',
                      height: 24,
                      width: 24,
                    ),
                    label: _isLoading
                        ? const CircularProgressIndicator(color: Colors.black)
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 12),
                              Text(
                                'Continue with Google',
                                style: TextStyle(color: Colors.black),
                              ),
                            ],
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      minimumSize: const Size(300, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
