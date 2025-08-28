import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logger/logger.dart';

class PoseSuggestion {
  final String title;
  final String description;
  final String instructions;
  final List<String> tips;
  final String category;
  final String? cameraSettings;

  PoseSuggestion({
    required this.title,
    required this.description,
    required this.instructions,
    required this.tips,
    required this.category,
    this.cameraSettings,
  });

  factory PoseSuggestion.fromJson(Map<String, dynamic> json) {
    return PoseSuggestion(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      instructions: json['instructions'] ?? '',
      tips: List<String>.from(json['tips'] ?? []),
      category: json['category'] ?? '',
      cameraSettings: json['cameraSettings'],
    );
  }
}

class GeminiPoseService extends GetxService {
  static GeminiPoseService get to => Get.find();

  final Logger _logger = Logger();
  GenerativeModel? _model;

  final RxBool _isLoading = false.obs;
  final RxBool _isAvailable = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxList<PoseSuggestion> _recentSuggestions = <PoseSuggestion>[].obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isAvailable => _isAvailable.value;
  String get errorMessage => _errorMessage.value;
  List<PoseSuggestion> get recentSuggestions => _recentSuggestions;

  // Reactive getters
  RxBool get isLoadingRx => _isLoading;
  RxBool get isAvailableRx => _isAvailable;
  RxString get errorMessageRx => _errorMessage;
  RxList<PoseSuggestion> get recentSuggestionsRx => _recentSuggestions;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initializeGemini();
  }

  /// Initialize Gemini AI service
  Future<void> _initializeGemini() async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        _isAvailable.value = false;
        _errorMessage.value = 'Gemini API key not configured';
        _logger.w('Gemini API key not found in .env file');
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.8,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
      );

      _isAvailable.value = true;
      _errorMessage.value = '';
      _logger.i('Gemini AI service initialized successfully');
    } catch (e) {
      _isAvailable.value = false;
      _errorMessage.value = 'Failed to initialize Gemini AI: ${e.toString()}';
      _logger.e('Error initializing Gemini AI: $e');
    }
  }

  /// Generate pose suggestions based on context
  Future<List<PoseSuggestion>> generatePoseSuggestions({
    required String photoType,
    String? location,
    String? mood,
    String? numberOfPeople,
    String? occasion,
  }) async {
    if (!_isAvailable.value) {
      throw Exception(
          'Gemini AI service is not available. Please check your API key configuration.');
    }

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final prompt = _buildPrompt(
        photoType: photoType,
        location: location,
        mood: mood,
        numberOfPeople: numberOfPeople,
        occasion: occasion,
      );

      final response = await _model!.generateContent([Content.text(prompt)]);
      final suggestions = _parsePoseSuggestions(response.text ?? '');

      // Add to recent suggestions
      _recentSuggestions.addAll(suggestions);
      if (_recentSuggestions.length > 20) {
        _recentSuggestions.removeRange(0, _recentSuggestions.length - 20);
      }

      _logger.i('Generated ${suggestions.length} pose suggestions');
      return suggestions;
    } catch (e) {
      _errorMessage.value =
          'Failed to generate pose suggestions: ${e.toString()}';
      _logger.e('Error generating pose suggestions: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Build prompt for Gemini AI
  String _buildPrompt({
    required String photoType,
    String? location,
    String? mood,
    String? numberOfPeople,
    String? occasion,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Generate 3-5 creative photography pose suggestions for the following context:');
    buffer.writeln('');
    buffer.writeln('Photo Type: $photoType');

    if (location != null && location.isNotEmpty) {
      buffer.writeln('Location: $location');
    }

    if (mood != null && mood.isNotEmpty) {
      buffer.writeln('Mood: $mood');
    }

    if (numberOfPeople != null && numberOfPeople.isNotEmpty) {
      buffer.writeln('Number of People: $numberOfPeople');
    }

    if (occasion != null && occasion.isNotEmpty) {
      buffer.writeln('Occasion: $occasion');
    }

    buffer.writeln('');
    buffer.writeln(
        'Please provide creative, detailed pose suggestions in the following JSON format:');
    buffer.writeln('{');
    buffer.writeln('  "suggestions": [');
    buffer.writeln('    {');
    buffer.writeln('      "title": "Pose Name",');
    buffer.writeln('      "description": "Brief description of the pose",');
    buffer.writeln(
        '      "instructions": "Step-by-step instructions for the pose",');
    buffer.writeln('      "tips": ["tip1", "tip2", "tip3"],');
    buffer.writeln('      "category": "portrait/landscape/action/creative",');
    buffer.writeln(
        '      "cameraSettings": "Recommended camera settings (aperture, shutter speed, ISO, focus mode, etc.)"');
    buffer.writeln('    }');
    buffer.writeln('  ]');
    buffer.writeln('}');
    buffer.writeln('');
    buffer.writeln(
        'Make the suggestions creative, practical, and suitable for the given context. Include specific body positioning, facial expressions, composition tips, and appropriate camera settings for capturing the required photo effectively.');

    return buffer.toString();
  }

  /// Parse pose suggestions from Gemini response
  List<PoseSuggestion> _parsePoseSuggestions(String response) {
    try {
      // Clean up the response to extract JSON
      String jsonStr = response;

      // Find JSON block
      final jsonStart = jsonStr.indexOf('{');
      final jsonEnd = jsonStr.lastIndexOf('}') + 1;

      if (jsonStart != -1 && jsonEnd > jsonStart) {
        jsonStr = jsonStr.substring(jsonStart, jsonEnd);
      }

      // Try to parse as JSON
      final Map<String, dynamic> data = {};

      // If JSON parsing fails, create fallback suggestions
      if (data.isEmpty || !data.containsKey('suggestions')) {
        return _createFallbackSuggestions(response);
      }

      final List<dynamic> suggestionsJson = data['suggestions'] ?? [];
      return suggestionsJson
          .map((json) => PoseSuggestion.fromJson(json))
          .toList();
    } catch (e) {
      _logger.w(
          'Failed to parse JSON response, creating fallback suggestions: $e');
      return _createFallbackSuggestions(response);
    }
  }

  /// Create fallback suggestions when JSON parsing fails
  List<PoseSuggestion> _createFallbackSuggestions(String response) {
    // Extract suggestions from plain text response
    final suggestions = <PoseSuggestion>[];

    // Split response into sections and try to extract pose ideas
    final lines = response.split('\n');
    String currentTitle = '';
    String currentDescription = '';
    String currentInstructions = '';
    List<String> currentTips = [];
    String currentCameraSettings = '';

    for (String line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      // Look for pose titles (usually numbered or have specific keywords)
      if (line.contains(RegExp(r'^\d+\.')) ||
          line.toLowerCase().contains('pose') ||
          line.toLowerCase().contains('shot') ||
          line.toLowerCase().contains('angle')) {
        // Save previous suggestion if we have one
        if (currentTitle.isNotEmpty) {
          suggestions.add(PoseSuggestion(
            title: currentTitle,
            description: currentDescription,
            instructions: currentInstructions,
            tips: List.from(currentTips),
            category: 'creative',
            cameraSettings:
                currentCameraSettings.isNotEmpty ? currentCameraSettings : null,
          ));
        }

        // Start new suggestion
        currentTitle = line.replaceAll(RegExp(r'^\d+\.\s*'), '');
        currentDescription = '';
        currentInstructions = '';
        currentTips.clear();
        currentCameraSettings = '';
      } else if (line.startsWith('-') || line.startsWith('•')) {
        // This is likely a tip or instruction
        currentTips.add(line.replaceAll(RegExp(r'^[-•]\s*'), ''));
      } else if (line.toLowerCase().contains('camera') ||
          line.toLowerCase().contains('aperture') ||
          line.toLowerCase().contains('iso') ||
          line.toLowerCase().contains('shutter')) {
        // This is likely camera settings
        currentCameraSettings +=
            (currentCameraSettings.isEmpty ? '' : ' ') + line;
      } else if (currentTitle.isNotEmpty) {
        // This is likely description or instructions
        if (currentDescription.isEmpty) {
          currentDescription = line;
        } else {
          currentInstructions +=
              (currentInstructions.isEmpty ? '' : ' ') + line;
        }
      }
    }

    // Add the last suggestion
    if (currentTitle.isNotEmpty) {
      suggestions.add(PoseSuggestion(
        title: currentTitle,
        description: currentDescription,
        instructions: currentInstructions,
        tips: List.from(currentTips),
        category: 'creative',
        cameraSettings:
            currentCameraSettings.isNotEmpty ? currentCameraSettings : null,
      ));
    }

    // If we still don't have suggestions, create some generic ones
    if (suggestions.isEmpty) {
      suggestions.addAll(_getGenericSuggestions());
    }

    return suggestions;
  }

  /// Get generic pose suggestions as fallback
  List<PoseSuggestion> _getGenericSuggestions() {
    return [
      PoseSuggestion(
        title: 'Natural Portrait',
        description: 'A relaxed, natural-looking portrait pose',
        instructions:
            'Stand or sit comfortably, slight angle to camera, gentle smile, hands relaxed',
        tips: [
          'Keep shoulders relaxed',
          'Slight chin forward',
          'Natural eye contact'
        ],
        category: 'portrait',
        cameraSettings:
            'Aperture: f/2.8-f/4, ISO: 100-400, Shutter: 1/125s, Focus: Single point AF on eyes',
      ),
      PoseSuggestion(
        title: 'Dynamic Action',
        description: 'Capture movement and energy',
        instructions:
            'Mid-motion pose, one foot forward, arms in natural swing position',
        tips: ['Use burst mode', 'Focus on expression', 'Consider background'],
        category: 'action',
        cameraSettings:
            'Aperture: f/5.6-f/8, ISO: 400-800, Shutter: 1/250s+, Focus: Continuous AF, Drive: Burst mode',
      ),
      PoseSuggestion(
        title: 'Creative Angle',
        description: 'Unique perspective shot',
        instructions:
            'Try low angle, high angle, or side profile for interesting composition',
        tips: [
          'Experiment with lighting',
          'Use rule of thirds',
          'Consider symmetry'
        ],
        category: 'creative',
        cameraSettings:
            'Aperture: f/8-f/11, ISO: 100-200, Shutter: 1/60s-1/125s, Focus: Single point AF',
      ),
    ];
  }

  /// Get pose suggestions by category
  Future<List<PoseSuggestion>> getPosesByCategory(String category) async {
    return generatePoseSuggestions(
      photoType: category,
      mood: 'creative',
    );
  }

  /// Get random pose suggestion
  Future<PoseSuggestion> getRandomPose() async {
    final categories = [
      'portrait',
      'landscape',
      'action',
      'creative',
      'candid'
    ];
    final randomCategory =
        categories[DateTime.now().millisecond % categories.length];

    final suggestions =
        await generatePoseSuggestions(photoType: randomCategory);
    return suggestions.isNotEmpty
        ? suggestions[DateTime.now().millisecond % suggestions.length]
        : _getGenericSuggestions().first;
  }

  /// Clear recent suggestions
  void clearRecentSuggestions() {
    _recentSuggestions.clear();
  }

  /// Check if service is properly configured
  bool isConfigured() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    return apiKey != null && apiKey.isNotEmpty;
  }
}
