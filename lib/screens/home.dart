import 'package:flutter/material.dart';
import 'package:smart_chef_app/auth/pages/login_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart'; // Add this dependency to pubspec.yaml
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // For TimeoutException
// For HttpException
import 'package:smart_chef_app/widgets/loading_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _showInitialContent = true;
  final stt.SpeechToText _speech = stt.SpeechToText();
  final bool _isListening = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late AnimationController _controller;
  bool _isExpanded = false;

  List<dynamic>? recipes;
  bool isLoading = false;

  int _page = 1;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();
  final int _itemsPerPage = 20;
  bool _isLoadingMore = false;

  List<Recipe> visibleRecipes = [];

  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scrollController.addListener(_scrollListener);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _fetchRecipes();
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreRecipes();
      }
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (_isLoadingMore) return;
    setState(() {
      _isLoadingMore = true;
    });
    await _fetchRecipes(
      query: _messageController.text,
      loadMore: true,
    );
  }

  Future<void> _fetchRecipes({String? query, bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _page = 1;
        isLoading = true;
        recipes = [];
        visibleRecipes = [];
        errorMessage = null;
      });
    }

    try {
      const apiKey = '3b29b6edd5cf45f883a012d80e646a06';
      const baseUrl = 'https://api.spoonacular.com/recipes/complexSearch';

      final queryParams = {
        'apiKey': apiKey,
        'number': '20',
        'offset': '${(_page - 1) * _itemsPerPage}',
        'addRecipeInformation': 'true',
        'instructionsRequired': 'true',
        'fillIngredients': 'true',
        if (query?.isEmpty ?? true) 'cuisine': 'indian',
        if (query?.isNotEmpty == true) 'query': query,
      };

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      print('Fetching from: $uri');

      final response = await http.get(uri);
      final data = json.decode(response.body);

      if (response.statusCode == 402) {
        print('API limit reached, using sample data');
        _useSampleData(loadMore);
        return;
      } else if (response.statusCode != 200) {
        _useSampleData(loadMore);
        return;
      }

      if (data['results'] == null || (data['results'] as List).isEmpty) {
        _useSampleData(loadMore);
        return;
      }

      final List<dynamic> recipeList = data['results'] as List;
      final totalResults = data['totalResults'] as int? ?? 0;

      final newRecipes = recipeList
          .map((recipe) {
            try {
              return Recipe(
                name: recipe['title'] ?? 'Unknown Recipe',
                description: recipe['summary']
                        ?.toString()
                        .replaceAll(RegExp(r'<[^>]*>'), '') ??
                    'No description available',
                imageUrl: recipe['image'] ?? 'https://via.placeholder.com/300',
                videoUrl: recipe['videoUrl'] ?? '',
                protein: 0.0,
                fats: 0.0,
                carbs: 0.0,
                steps: _extractInstructions(recipe),
                cookTime: recipe['readyInMinutes'] ?? 0,
                servings: recipe['servings'] ?? 0,
                nutrients: <String, double>{},
                reviews: 0,
              );
            } catch (e) {
              print('Error parsing recipe: $e');
              return null;
            }
          })
          .whereType<Recipe>()
          .toList();

      if (newRecipes.isEmpty) {
        throw Exception('Failed to parse recipes');
      }

      setState(() {
        if (loadMore) {
          recipes?.addAll(newRecipes);
          visibleRecipes
              .addAll(newRecipes); // Immediately add all recipes for load more
        } else {
          recipes = newRecipes;
          visibleRecipes =
              newRecipes; // Immediately show all recipes for initial load
        }
        _hasMore = (recipes?.length ?? 0) < totalResults;
        _page++;
        _showInitialContent = false;
        isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      print('Error: $e');
      _useSampleData(loadMore);
    }
  }

  void _useSampleData(bool loadMore) {
    // Sample recipe data
    final sampleRecipes = [
      Recipe(
        name: 'Butter Chicken',
        description: 'Classic Indian butter chicken with rich and creamy sauce',
        imageUrl: 'assets/svgs/1.png', // Use your local assets
        videoUrl: '',
        protein: 25.0,
        fats: 15.0,
        carbs: 10.0,
        steps: [
          'Marinate chicken',
          'Prepare sauce',
          'Cook chicken',
          'Combine and simmer'
        ],
        cookTime: 45,
        servings: 4,
        nutrients: {'Protein': 25.0, 'Fat': 15.0, 'Carbs': 10.0},
        reviews: 4,
      ),
      Recipe(
        name: 'Paneer Tikka',
        description: 'Grilled Indian cottage cheese with spices',
        imageUrl: 'assets/svgs/2.png',
        videoUrl: '',
        protein: 18.0,
        fats: 12.0,
        carbs: 8.0,
        steps: [
          'Cut paneer into cubes',
          'Marinate with spices',
          'Grill until charred'
        ],
        cookTime: 30,
        servings: 3,
        nutrients: {'Protein': 18.0, 'Fat': 12.0, 'Carbs': 8.0},
        reviews: 3,
      ),
      // Add more sample recipes as needed
    ];

    setState(() {
      if (loadMore) {
        recipes?.addAll(sampleRecipes);
        visibleRecipes.addAll(sampleRecipes);
      } else {
        recipes = sampleRecipes;
        visibleRecipes = sampleRecipes;
      }
      _hasMore = false; // Disable load more for sample data
      _page++;
      _showInitialContent = false;
      isLoading = false;
      _isLoadingMore = false;
      errorMessage = null;
    });
  }

  Recipe _parseRecipe(Map<String, dynamic> recipe) {
    // Extract nutrition information
    final nutrients = recipe['nutrition']?['nutrients'] as List? ?? [];
    final nutritionInfo = <String, double>{};

    for (var nutrient in nutrients) {
      nutritionInfo[nutrient['name']] = (nutrient['amount'] as num).toDouble();
    }

    return Recipe(
      name: recipe['title'] ?? 'Unknown Recipe',
      description:
          recipe['summary']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ??
              'No description available',
      imageUrl: recipe['image'] ?? 'https://via.placeholder.com/300',
      videoUrl: recipe['videoUrl'] ?? '',
      protein: nutritionInfo['Protein'] ?? 0.0,
      fats: nutritionInfo['Fat'] ?? 0.0,
      carbs: nutritionInfo['Carbohydrates'] ?? 0.0,
      steps: _extractInstructions(recipe),
      cookTime: recipe['readyInMinutes'] ?? 0,
      servings: recipe['servings'] ?? 0,
      nutrients: nutritionInfo,
      reviews: recipe['analyzedInstructions']?[0]?['steps']?.length ?? 0,
    );
  }

  // Helper method to extract instructions
  List<String> _extractInstructions(Map<String, dynamic> recipe) {
    try {
      if (recipe['analyzedInstructions'] != null &&
          recipe['analyzedInstructions'].isNotEmpty) {
        final steps = recipe['analyzedInstructions'][0]['steps'] as List;
        return steps
            .map((step) => step['step'].toString())
            .where((step) => step.isNotEmpty)
            .toList();
      } else if (recipe['instructions'] != null) {
        return [recipe['instructions'].toString()];
      }
    } catch (e) {
      print('Error extracting instructions: $e');
    }
    return ['No instructions available'];
  }

  void _initializeSpeech() async {
    await _speech.initialize();
    setState(() {});
  }

  void _startListening() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _ListeningDialog(
          onResult: (String text) {
            setState(() {
              _messageController.text = text;
            });
          },
          speech: _speech,
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showModelSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Select Model',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModelOption(
                  'TF-IDF', 'Term Frequency-Inverse Document Frequency'),
              const SizedBox(height: 8),
              _buildModelOption(
                  'BERT', 'Bidirectional Encoder Representations'),
              const SizedBox(height: 8),
              _buildModelOption('ANN', 'Artificial Neural Network'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelOption(String title, String subtitle) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey,
          size: 16,
        ),
        onTap: () {
          Navigator.pop(context);
          // Handle model selection
        },
      ),
    );
  }

  void _showOptionsMenu() {
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 80, 0, 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey[900],
      items: [
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.refresh, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Reset Chat',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _showInitialContent = true;
              _messageController.clear();
            });
          },
        ),
        PopupMenuItem(
          child: const Row(
            children: [
              Icon(Icons.chat_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'New Chat',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          onTap: () {
            setState(() {
              _showInitialContent = true;
              _messageController.clear();
            });
          },
        ),
      ],
    );
  }

  void _toggleCard(int index) {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginPage();
    }

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: LoadingScreen(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.food_bank, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Smart-Chef',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.white),
            onPressed: _showOptionsMenu,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: _showModelSelectionDialog,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color.fromARGB(255, 20, 20, 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search chats...',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey,
                    size: 20,
                  ),
                  filled: false,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Recent Chats',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _buildHistoryItem(
                    'Italian Pasta Recipe',
                    'Yesterday',
                    Icons.restaurant,
                  ),
                  _buildHistoryItem(
                    'Baking Tips',
                    '2 days ago',
                    Icons.cake,
                  ),
                  _buildHistoryItem(
                    'Meal Planning',
                    '3 days ago',
                    Icons.calendar_today,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: Text(
                      _auth.currentUser?.email ?? 'Guest User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      _auth.currentUser != null ? 'Signed In' : 'Free Account',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await _auth.signOut();
                          // Clear any stored credentials or user data
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.clear();

                          if (mounted) {
                            // Close drawer
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error signing out: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text(
                        'Logout',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _showInitialContent
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final bool isKeyboardOpen =
                          MediaQuery.of(context).viewInsets.bottom > 0;
                      final double logoSize = isKeyboardOpen ? 120.0 : 250.0;
                      final double titleSize = isKeyboardOpen ? 24.0 : 30.0;
                      final double spacing = isKeyboardOpen ? 10.0 : 20.0;

                      return Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Hero(
                                tag: 'chef_image',
                                child: Container(
                                  height: logoSize,
                                  width: logoSize,
                                  decoration: const BoxDecoration(
                                    color: Colors.transparent,
                                  ),
                                  child: Image.asset(
                                    'assets/svgs/2.png',
                                    fit: BoxFit.contain,
                                    colorBlendMode: BlendMode.srcIn,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading gif: $error');
                                      return Icon(
                                        Icons.restaurant_menu,
                                        size: logoSize * 0.6,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing),
                              Hero(
                                tag: 'app_title',
                                child: Material(
                                  color: Colors.transparent,
                                  child: Text(
                                    'What can I help with?',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: spacing * 1.5),
                              Wrap(
                                spacing: 16,
                                runSpacing: 16,
                                alignment: WrapAlignment.center,
                                children: [
                                  _buildFeatureButton(
                                    icon: Icons.restaurant_menu,
                                    label: 'Generate Recipe',
                                    onTap: () {},
                                    iconColor: Colors.greenAccent,
                                  ),
                                  _buildFeatureButton(
                                    icon: Icons.food_bank,
                                    label: 'Recipe Ideas',
                                    onTap: () {},
                                    iconColor: Colors.blueAccent,
                                  ),
                                  _buildFeatureButton(
                                    icon: Icons.search,
                                    label: 'Browse Recipes',
                                    onTap: () => _fetchRecipes(),
                                    iconColor: Colors.orangeAccent,
                                  ),
                                ],
                              ),
                              if (!isKeyboardOpen) ...[
                                SizedBox(height: spacing),
                                TextButton(
                                  onPressed: () {},
                                  child: SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width - 90,
                                    child: const Text(
                                      'Lets get started by adding your ingredients or add a recipe.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w300,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _messageController.text.isNotEmpty
                                  ? 'Results for "${_messageController.text}"'
                                  : 'Popular Indian Recipes',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Found ${recipes?.length ?? 0} recipes',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.7,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemCount: visibleRecipes.length,
                          itemBuilder: (context, index) {
                            return AnimatedBuilder(
                              animation: Tween<double>(begin: 0, end: 1).animate(
                                CurvedAnimation(
                                  parent: ModalRoute.of(context)!.animation!,
                                  curve: Interval(
                                    (index * 0.1).clamp(0, 1),
                                    ((index + 1) * 0.1).clamp(0, 1),
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                              ),
                              builder: (context, child) {
                                return SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.2),
                                    end: Offset.zero,
                                  ).animate(
                                    CurvedAnimation(
                                      parent: ModalRoute.of(context)!.animation!,
                                      curve: Interval(
                                        (index * 0.1).clamp(0, 1),
                                        ((index + 1) * 0.1).clamp(0, 1),
                                        curve: Curves.easeInOut,
                                      ),
                                    ),
                                  ),
                                  child: FadeTransition(
                                    opacity: Tween<double>(begin: 0, end: 1).animate(
                                      CurvedAnimation(
                                        parent: ModalRoute.of(context)!.animation!,
                                        curve: Interval(
                                          (index * 0.1).clamp(0, 1),
                                          ((index + 1) * 0.1).clamp(0, 1),
                                          curve: Curves.easeInOut,
                                        ),
                                      ),
                                    ),
                                    child: VideoCard(recipe: visibleRecipes[index]),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewPadding.bottom + 8,
                top: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 45,
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            setState(() {
                              _showInitialContent = false;
                            });
                            _fetchRecipes(query: value);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search recipes...',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[900],
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.mic, size: 20),
                            onPressed: _startListening,
                          ),
                        ),
                        textAlignVertical: TextAlignVertical.center,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      size: 32,
                      color: Color.fromARGB(255, 238, 115, 0),
                    ),
                    onPressed: () {
                      if (_messageController.text.isNotEmpty) {
                        setState(() {
                          _showInitialContent = false;
                        });
                        _fetchRecipes(query: _messageController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String title, String time, IconData icon) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        time,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
        ),
      ),
      onTap: () {
        // Handle history item tap
      },
    );
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Material(
        color: Colors.grey[900],
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 160,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 24),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ListeningDialog extends StatefulWidget {
  final Function(String) onResult;
  final stt.SpeechToText speech;

  const _ListeningDialog({
    required this.onResult,
    required this.speech,
  });

  @override
  State<_ListeningDialog> createState() => _ListeningDialogState();
}

class _ListeningDialogState extends State<_ListeningDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _text = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startListening();
  }

  void _startListening() async {
    setState(() => _isListening = true);
    await widget.speech.listen(
      onResult: (result) {
        setState(() {
          _text = result.recognizedWords;
        });
      },
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  void _stopListening() async {
    await widget.speech.stop();
    setState(() => _isListening = false);
    widget.onResult(_text);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Dimmed background
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.7), // Darker overlay
          ),
        ),
        // Dialog content
        Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[900]?.withOpacity(0.7),
                      border: Border.all(
                        color: Colors.blue.withOpacity(
                          0.5 + (_animationController.value * 0.5),
                        ),
                        width: 6,
                      ),
                    ),
                    child: const Icon(
                      Icons.keyboard_voice_rounded,
                      color: Colors.blue,
                      size: 80,
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[900]?.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isListening ? 'Listening...' : 'Tap to speak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
              if (_text.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[900]?.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: _stopListening,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.grey[900]?.withOpacity(0.7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

class Recipe {
  final String name;
  final String description;
  final String imageUrl;
  final String? videoUrl;
  final double protein;
  final double fats;
  final double carbs;
  final List<String> steps;
  final int cookTime;
  final int servings;
  final Map<String, double> nutrients;
  final int reviews;

  Recipe({
    required this.name,
    required this.description,
    required this.imageUrl,
    this.videoUrl,
    required this.protein,
    required this.fats,
    required this.carbs,
    required this.steps,
    required this.cookTime,
    required this.servings,
    required this.nutrients,
    required this.reviews,
  });
}

class VideoCard extends StatefulWidget {
  final Recipe recipe;

  const VideoCard({
    required this.recipe,
    super.key,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailedView(context),
      child: Card(
        elevation: 4,
        color: Colors.grey[900],
        child: SizedBox(
          height: 280, // Fixed height for all cards
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.network(
                  widget.recipe.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 120,
                      color: Colors.grey[800],
                      child: const Icon(Icons.restaurant, color: Colors.white),
                    );
                  },
                ),
              ),
              // Content Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.recipe.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Cooking Time
                      Row(
                        children: [
                          Icon(Icons.timer, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.recipe.cookTime} min',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Description
                      Text(
                        widget.recipe.description,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(), // Pushes Read More button to bottom
                      // Read More Button
                      Align(
                        alignment:
                            Alignment.centerLeft, // Aligns button to the left
                        child: Container(
                          width:
                              120, // Fixed width for the button (approximately half)
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 14,
                                color: Colors.grey[900],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Read More',
                                style: TextStyle(
                                  color: Colors.grey[900],
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailedView(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Hero(
          tag: 'recipe-${widget.recipe.name}',
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  // Header image and close button
                  SizedBox(
                    height: 200,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16)),
                          child: Image.network(
                            widget.recipe.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Close button
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title and basic info
                            Text(
                              widget.recipe.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Cooking info
                            Row(
                              children: [
                                _buildInfoChip(Icons.timer,
                                    '${widget.recipe.cookTime} min'),
                                const SizedBox(width: 8),
                                _buildInfoChip(Icons.restaurant,
                                    '${widget.recipe.servings} servings'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Description
                            Text(
                              widget.recipe.description,
                              style: const TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 24),
                            // Nutrition section
                            const Text(
                              'Nutritional Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 250, // Fixed height for chart
                              child: NutritionChart(
                                protein: widget.recipe.protein,
                                fats: widget.recipe.fats,
                                carbs: widget.recipe.carbs,
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Instructions
                            const Text(
                              'Instructions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.recipe.steps.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          widget.recipe.steps[index],
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
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
        ),
      ),
    );
  }

  // Helper method for info chips
  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class NutritionChart extends StatelessWidget {
  final double protein;
  final double fats;
  final double carbs;

  const NutritionChart({
    required this.protein,
    required this.fats,
    required this.carbs,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: protein,
                  title: '${protein.toStringAsFixed(1)}g',
                  color: const Color(0xFF2196F3), // Bright blue
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: fats,
                  title: '${fats.toStringAsFixed(1)}g',
                  color: const Color(0xFFFF4081), // Bright pink
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: carbs,
                  title: '${carbs.toStringAsFixed(1)}g',
                  color: const Color(0xFF4CAF50), // Bright green
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem('Protein', const Color(0xFF2196F3)),
            _buildLegendItem('Fats', const Color(0xFFFF4081)),
            _buildLegendItem('Carbs', const Color(0xFF4CAF50)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
