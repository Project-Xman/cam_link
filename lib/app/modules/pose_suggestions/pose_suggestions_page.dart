import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/gemini_pose_service.dart';
import '../../core/values/app_values.dart';

class PoseSuggestionsPage extends StatefulWidget {
  const PoseSuggestionsPage({super.key});

  @override
  State<PoseSuggestionsPage> createState() => _PoseSuggestionsPageState();
}

class _PoseSuggestionsPageState extends State<PoseSuggestionsPage> {
  final GeminiPoseService _poseService = GeminiPoseService.to;
  final List<PoseSuggestion> _suggestions = [];
  
  // Form controllers
  final _photoTypeController = TextEditingController(text: 'Portrait');
  final _locationController = TextEditingController();
  final _moodController = TextEditingController();
  final _numberOfPeopleController = TextEditingController(text: '1');
  final _occasionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkServiceAvailability();
  }

  void _checkServiceAvailability() {
    if (!_poseService.isConfigured()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showComingSoonDialog();
      });
    }
  }

  void _showComingSoonDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Coming Soon'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Colors.orange,
            ),
            SizedBox(height: AppValues.paddingMedium),
            Text(
              'AI-powered pose suggestions are coming soon!\n\nTo enable this feature, please configure your Gemini API key in the .env file.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              Get.back(); // Go back to previous page
            },
            child: const Text('OK'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Pose Suggestions'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _getRandomPose,
            tooltip: 'Random Pose',
          ),
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearSuggestions,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Obx(() {
        if (!_poseService.isAvailable) {
          return _buildComingSoonView();
        }

        return Column(
          children: [
            _buildInputForm(),
            Expanded(
              child: _buildSuggestionsList(),
            ),
          ],
        );
      }),
      floatingActionButton: Obx(() {
        if (!_poseService.isAvailable) return const SizedBox.shrink();
        
        return FloatingActionButton.extended(
          onPressed: _poseService.isLoading ? null : _generateSuggestions,
          icon: _poseService.isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(_poseService.isLoading ? 'Generating...' : 'Generate Poses'),
        );
      }),
    );
  }

  Widget _buildComingSoonView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_camera_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: AppValues.paddingLarge),
            Text(
              'AI Pose Suggestions',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Text(
              'Coming Soon!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Text(
              'Get creative photography pose suggestions powered by Gemini AI.\n\nTo enable this feature, configure your Gemini API key in the app settings.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppValues.paddingLarge),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppValues.paddingMedium),
                child: Column(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Colors.orange),
                    const SizedBox(height: AppValues.paddingSmall),
                    Text(
                      'Preview Features',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppValues.paddingSmall),
                    const Text(
                      '• Personalized pose suggestions\n'
                      '• Context-aware recommendations\n'
                      '• Creative photography tips\n'
                      '• Multiple pose categories',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Card(
      margin: const EdgeInsets.all(AppValues.paddingMedium),
      child: Padding(
        padding: const EdgeInsets.all(AppValues.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Describe Your Photo Session',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _photoTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Photo Type',
                      hintText: 'Portrait, Landscape, Action...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppValues.paddingSmall),
                Expanded(
                  child: TextField(
                    controller: _numberOfPeopleController,
                    decoration: const InputDecoration(
                      labelText: 'People',
                      hintText: '1, 2, Group...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingSmall),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location (Optional)',
                      hintText: 'Beach, Studio, Park...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppValues.paddingSmall),
                Expanded(
                  child: TextField(
                    controller: _moodController,
                    decoration: const InputDecoration(
                      labelText: 'Mood (Optional)',
                      hintText: 'Happy, Serious, Playful...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppValues.paddingSmall),
            TextField(
              controller: _occasionController,
              decoration: const InputDecoration(
                labelText: 'Occasion (Optional)',
                hintText: 'Wedding, Birthday, Casual...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppValues.paddingMedium),
            Text(
              'No pose suggestions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppValues.paddingSmall),
            Text(
              'Fill in the details above and tap "Generate Poses" to get AI-powered suggestions',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppValues.paddingMedium),
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        return _buildSuggestionCard(suggestion, index);
      },
    );
  }

  Widget _buildSuggestionCard(PoseSuggestion suggestion, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppValues.paddingMedium),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          suggestion.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(suggestion.description),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppValues.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (suggestion.instructions.isNotEmpty) ...[
                  Text(
                    'Instructions:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppValues.paddingSmall),
                  Text(suggestion.instructions),
                  const SizedBox(height: AppValues.paddingMedium),
                ],
                if (suggestion.tips.isNotEmpty) ...[
                  Text(
                    'Tips:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppValues.paddingSmall),
                  ...suggestion.tips.map((tip) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: AppValues.paddingSmall),
                Chip(
                  label: Text(suggestion.category.toUpperCase()),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateSuggestions() async {
    try {
      final suggestions = await _poseService.generatePoseSuggestions(
        photoType: _photoTypeController.text.trim(),
        location: _locationController.text.trim().isEmpty 
            ? null 
            : _locationController.text.trim(),
        mood: _moodController.text.trim().isEmpty 
            ? null 
            : _moodController.text.trim(),
        numberOfPeople: _numberOfPeopleController.text.trim().isEmpty 
            ? null 
            : _numberOfPeopleController.text.trim(),
        occasion: _occasionController.text.trim().isEmpty 
            ? null 
            : _occasionController.text.trim(),
      );

      setState(() {
        _suggestions.clear();
        _suggestions.addAll(suggestions);
      });

      if (suggestions.isNotEmpty) {
        Get.snackbar(
          'Success',
          'Generated ${suggestions.length} pose suggestions!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to generate pose suggestions: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      );
    }
  }

  Future<void> _getRandomPose() async {
    try {
      final suggestion = await _poseService.getRandomPose();
      setState(() {
        _suggestions.clear();
        _suggestions.add(suggestion);
      });

      Get.snackbar(
        'Random Pose',
        'Here\'s a creative pose idea for you!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get random pose: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
      );
    }
  }

  void _clearSuggestions() {
    setState(() {
      _suggestions.clear();
    });
    _poseService.clearRecentSuggestions();
  }

  @override
  void dispose() {
    _photoTypeController.dispose();
    _locationController.dispose();
    _moodController.dispose();
    _numberOfPeopleController.dispose();
    _occasionController.dispose();
    super.dispose();
  }
}