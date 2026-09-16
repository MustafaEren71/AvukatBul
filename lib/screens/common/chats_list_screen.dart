import 'package:flutter/material.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/models/message_model.dart';
import 'package:avukatbul/models/user_model.dart';
import 'package:avukatbul/screens/common/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ChatsListScreen extends StatefulWidget {
  @override
  _ChatsListScreenState createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getChats(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Sohbetler yüklenirken bir hata oluştu: ${snapshot.error}'),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          
          List<Map<String, dynamic>> chats = snapshot.data ?? [];
          
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Henüz mesajınız yok',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Avukat profillerinden mesaj gönderebilirsiniz',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              UserModel user = chats[index]['user'];
              MessageModel lastMessage = chats[index]['lastMessage'];
              
              return ListTile(
                leading: _buildUserAvatar(user),
                title: Text(
                  user.name.isNotEmpty ? user.name : 'İsimsiz Kullanıcı',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  lastMessage.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getFormattedTime(lastMessage.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 4),
                    // Okunmamış mesaj sayısı gösterilebilir
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: user.id,
                        receiverName: user.name.isNotEmpty ? user.name : 'İsimsiz Kullanıcı',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  
  Widget _buildUserAvatar(UserModel user) {
    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: user.profileImageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => _buildDefaultAvatar(user),
        ),
      );
    } else {
      return _buildDefaultAvatar(user);
    }
  }
  
  Widget _buildDefaultAvatar(UserModel user) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        user.name.isNotEmpty ? user.name.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  String _getFormattedTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return DateFormat('HH:mm').format(date);
    } else if (dateToCheck == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('dd/MM').format(date);
    }
  }
}
