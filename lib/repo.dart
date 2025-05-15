import 'dart:convert';
import 'package:http/http.dart' as http;

class VoiceAssistantService {
  // For Android emulator:
  static const String _baseUrl = "http://127.0.0.1:5000";
  // For physical device or iOS simulator, change accordingly

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<Map<String, dynamic>> predictIntent(String userInput) async {
    _setLoading(true);
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/predict_intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': userInput}),
      );
      _setLoading(false);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Error response body: ${response.body}');
        throw Exception(
          'Failed to load intent prediction. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      _setLoading(false);
      return _handleError(e);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    // Ideally, notify listeners here if using state management
  }

  Map<String, dynamic> _handleError(error) {
    if (error is Exception) {
      return {'error': true, 'message': 'An error occurred: $error'};
    } else {
      return {
        'error': true,
        'message': 'Something went wrong, please try again later.',
      };
    }
  }
}
