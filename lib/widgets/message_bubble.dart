import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final String time;
  
  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.time,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe 
            ? Theme.of(context).primaryColor 
            : Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isMe ? Radius.circular(0) : null,
            bottomLeft: !isMe ? Radius.circular(0) : null,
          ),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 4),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: TextStyle(
                  color: isMe ? Colors.white.withOpacity(0.7) : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
