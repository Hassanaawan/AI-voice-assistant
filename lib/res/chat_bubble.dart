import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String sender;
  final String time;
  final bool isRecording;

  ChatBubble({
    required this.message,
    required this.sender,
    required this.time,
    this.isRecording = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUser = sender == 'user';
    final theme = Theme.of(context);

    final bubbleColor =
        isUser
            ? theme.colorScheme.primary
            : theme.colorScheme.surface.withOpacity(0.1);

    final textColor =
        isUser
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface.withOpacity(0.7);

    final secondaryTextColor =
        isUser
            ? theme.colorScheme.onPrimary.withOpacity(0.7)
            : theme.colorScheme.onSurface.withOpacity(0.4);

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            isUser ? "You said" : "Assistant reply",
            style: TextStyle(color: secondaryTextColor, fontSize: 12),
          ),
        ),
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 3,
                  offset: Offset(1, 2),
                ),
              ],
            ),
            child:
                isRecording
                    ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 8),
                        Text(
                          message,
                          style: TextStyle(color: textColor, fontSize: 16),
                        ),
                      ],
                    )
                    : Text(
                      message,
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
          child: Text(
            time,
            style: TextStyle(color: secondaryTextColor, fontSize: 10),
          ),
        ),
      ],
    );
  }
}
