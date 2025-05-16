import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fyp_voice/repo.dart';
import 'package:fyp_voice/res/chat_bubble.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../main.dart';

class VoiceAssistantScreen extends StatefulWidget {
  @override
  _VoiceAssistantScreenState createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen> {
  final ScrollController _scrollController = ScrollController();
  final VoiceAssistantService _voiceAssistantService = VoiceAssistantService();
  final FlutterTts _flutterTts = FlutterTts();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _hasHandledSpeech = false;
  String _spokenText = "";
  List<Map<String, String>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initializeTTS();
    _checkAndRequestPermissions();
    _loadChatMessages();
  }

  void _initializeTTS() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.9);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _flutterTts.stop(); // ensure previous TTS is cleared
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _speech.stop();
    _scrollController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  Future<bool> _checkAndRequestPermissions() async {
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    return status.isGranted;
  }

  Future<void> _loadChatMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedChats = prefs.getString('chatMessages');
    if (savedChats != null) {
      List<dynamic> decoded = jsonDecode(savedChats);
      if (mounted) {
        setState(() {
          _chatMessages =
              decoded
                  .map<Map<String, String>>((e) => Map<String, String>.from(e))
                  .toList();
        });
        _scrollToBottom();
      }
    }
  }

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
              _hasHandledSpeech = true;
              if (mounted) setState(() => _isListening = false);
              _updateLastUserMessage(_spokenText);
              await _predictIntent(_spokenText);
            }
          },
          onError: (val) {
            debugPrint("Speech Error: ${val.errorMsg}");
            if (mounted) {
              setState(() {
                _isListening = false;
                _spokenText = "";
              });
            }
          },
        );

        if (available && mounted) {
          setState(() {
            _isListening = true;
            _spokenText = "";
            _hasHandledSpeech = false;
            _addChatMessage('user', '', isRecording: true);
          });

          _speech.listen(
            onResult: (val) {
              if (mounted) {
                setState(() {
                  _spokenText = val.recognizedWords;
                  _updateLastUserMessage("You said: $_spokenText");
                });
              }
            },
            cancelOnError: true,
          );
        }
      }
    } else {
      if (mounted) setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _updateLastUserMessage(String newMessage) {
    if (_chatMessages.isNotEmpty && _chatMessages.last['sender'] == 'user') {
      if (mounted) {
        setState(() {
          _chatMessages[_chatMessages.length - 1]['message'] = newMessage;
          _chatMessages[_chatMessages.length - 1]['isRecording'] = 'false';
        });
      }
      _saveChatMessages();
    }
  }

  void _addChatMessage(
    String sender,
    String message, {
    bool isRecording = false,
  }) {
    if (mounted) {
      setState(() {
        _chatMessages.add({
          'sender': sender,
          'message': isRecording ? "Recording..." : message,
          'time': DateFormat('hh:mm a').format(DateTime.now()),
          'isRecording': isRecording.toString(),
        });
        _scrollToBottom();
      });
    }
    _saveChatMessages();
  }

  Future<void> _saveReminder(String reminderText) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> existingReminders = prefs.getStringList('reminders') ?? [];

    final skipPhrases = [
      "add reminder",
      "set a reminder",
      "remind me to",
      "remind me",
      "create reminder",
      "schedule reminder",
    ];

    String cleaned = reminderText.toLowerCase();
    for (final phrase in skipPhrases) {
      if (cleaned.startsWith(phrase)) {
        cleaned = cleaned.replaceFirst(phrase, '').trim();
        break;
      }
    }

    if (cleaned.isEmpty) {
      cleaned = reminderText;
    }

    final formattedTime = DateFormat('EEEE, h:mm a').format(DateTime.now());
    final newReminder = jsonEncode({'title': cleaned, 'time': formattedTime});

    existingReminders.add(newReminder);
    await prefs.setStringList('reminders', existingReminders);

    debugPrint("📌 Reminder saved: $cleaned");
  }

  Future<void> _predictIntent(String input) async {
    if (input.trim().isEmpty) return;
    try {
      var response = await _voiceAssistantService.predictIntent(input);
      if (mounted) {
        String assistantReply = response['response'] ?? "No response.";
        if (response['error'] == true) {
          _addChatMessage(
            'assistant',
            response['message'] ?? "An error occurred.",
          );
          await _speak(response['message'] ?? "An error occurred.");
        } else {
          _addChatMessage('assistant', assistantReply);
          await _speak(assistantReply); // SPEAK THE RESPONSE
          if (response['intent']?.toLowerCase() == 'reminder') {
            await _saveReminder(input);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _addChatMessage('assistant', "Error: $e");
        await _speak("Sorry, there was an error.");
      }
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
