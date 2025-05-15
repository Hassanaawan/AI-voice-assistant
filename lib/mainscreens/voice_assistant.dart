import 'dart:convert'; // For json encode/decode
import 'package:flutter/material.dart';
import 'package:fyp_voice/repo.dart'; // Your API service wrapper
import 'package:fyp_voice/res/chat_bubble.dart'; // Your ChatBubble widget
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import '../main.dart'; // For themeNotifier

class VoiceAssistantScreen extends StatefulWidget {
  @override
  _VoiceAssistantScreenState createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final ScrollController _scrollController = ScrollController();
  final VoiceAssistantService _voiceAssistantService = VoiceAssistantService();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _hasHandledSpeech = false; // Prevent duplicate replies
  String _spokenText = "";
  List<Map<String, String>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _checkAndRequestPermissions();
    _loadChatMessages();
  }

  Future<bool> _checkAndRequestPermissions() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  // Load saved chat messages from SharedPreferences
  Future<void> _loadChatMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedChats = prefs.getString('chatMessages');
    if (savedChats != null) {
      List<dynamic> decoded = jsonDecode(savedChats);
      setState(() {
        _chatMessages =
            decoded
                .map<Map<String, String>>((e) => Map<String, String>.from(e))
                .toList();
      });
      _scrollToBottom();
    }
  }

  // Save chat messages to SharedPreferences
  Future<void> _saveChatMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String encoded = jsonEncode(_chatMessages);
    await prefs.setString('chatMessages', encoded);
  }

  void _listen() async {
    if (!_isListening) {
      if (await _checkAndRequestPermissions()) {
        bool available = await _speech.initialize(
          onStatus: (val) async {
            debugPrint("Speech Status: $val");
            if ((val == 'done' || val == 'notListening') &&
                !_hasHandledSpeech &&
                _spokenText.isNotEmpty) {
              _hasHandledSpeech = true; // Prevent multiple predictions
              setState(() => _isListening = false);
              _updateLastUserMessage(_spokenText);
              await _predictIntent(_spokenText);
            }
          },
          onError: (val) {
            debugPrint("Speech Error: ${val.errorMsg}");
            setState(() {
              _isListening = false;
              _spokenText = "";
            });
          },
        );

        if (available) {
          setState(() {
            _isListening = true;
            _spokenText = "";
            _hasHandledSpeech = false; // Reset
            _addChatMessage('user', '', isRecording: true);
          });

          _speech.listen(
            onResult: (val) {
              setState(() {
                _spokenText = val.recognizedWords;
                _updateLastUserMessage("You said: $_spokenText");
              });
            },
            cancelOnError: true,
          );
        }
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _updateLastUserMessage(String newMessage) {
    if (_chatMessages.isNotEmpty && _chatMessages.last['sender'] == 'user') {
      setState(() {
        _chatMessages[_chatMessages.length - 1]['message'] = newMessage;
        _chatMessages[_chatMessages.length - 1]['isRecording'] = 'false';
      });
      _saveChatMessages();
    }
  }

  void _addChatMessage(
    String sender,
    String message, {
    bool isRecording = false,
  }) {
    setState(() {
      _chatMessages.add({
        'sender': sender,
        'message': isRecording ? "Recording..." : message,
        'time': DateFormat('hh:mm a').format(DateTime.now()),
        'isRecording': isRecording.toString(),
      });
      _scrollToBottom();
    });
    _saveChatMessages();
  }

  // Save reminder to SharedPreferences
  Future<void> _saveReminder(String reminderText) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> existingReminders = prefs.getStringList('reminders') ?? [];
    // Save reminder with timestamp
    final formattedTime = DateFormat('EEEE, h:mm a').format(DateTime.now());
    final newReminder = jsonEncode({
      'title': reminderText,
      'time': formattedTime,
    });
    existingReminders.add(newReminder);
    await prefs.setStringList('reminders', existingReminders);
    debugPrint("📌 Reminder saved: $reminderText");
  }

  Future<void> _predictIntent(String input) async {
    if (input.trim().isEmpty) return;
    try {
      var response = await _voiceAssistantService.predictIntent(input);
      if (response['error'] == true) {
        _addChatMessage(
          'assistant',
          response['message'] ?? "An unknown error occurred.",
        );
      } else {
        _addChatMessage('assistant', response['response'] ?? "");
        // Save reminder if intent is reminder
        if (response['intent']?.toLowerCase() == 'reminder') {
          await _saveReminder(input);
        }
      }
    } catch (e) {
      _addChatMessage('assistant', "Error: $e");
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "AI Voice Assistant",
          style: theme.appBarTheme.titleTextStyle,
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              themeNotifier.value == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: theme.iconTheme.color,
            ),
            onPressed: () {
              themeNotifier.value =
                  themeNotifier.value == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                var msg = _chatMessages[index];
                return ChatBubble(
                  message: msg['message']!,
                  sender: msg['sender']!,
                  time: msg['time']!,
                  isRecording: msg['isRecording'] == 'true',
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _isListening ? "Listening..." : "Tap microphone to speak",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                FloatingActionButton(
                  onPressed: _listen,
                  child: Icon(_isListening ? Icons.mic_off : Icons.mic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
