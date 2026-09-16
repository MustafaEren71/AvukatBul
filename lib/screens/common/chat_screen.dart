import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/models/message_model.dart';
import 'package:avukatbul/models/user_model.dart';
import 'package:avukatbul/widgets/message_bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  
  const ChatScreen({
    Key? key,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);
  
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  UserModel? _receiver;
  
  @override
  void initState() {
    super.initState();
    _loadReceiverDetails();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _loadReceiverDetails() async {
    try {
      UserModel? user = await _firestoreService.getUserById(widget.receiverId);
      setState(() {
        _receiver = user;
      });
    } catch (e) {
      print('Alıcı bilgileri yükleme hatası: $e');
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildReceiverAvatar(),
            SizedBox(width: 8),
            Text(widget.receiverName),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              // Profil bilgilerini göster
              // TODO: Profil detay sayfasına yönlendir
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _firestoreService.getMessages(widget.receiverId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Mesajlar yüklenirken bir hata oluştu: ${snapshot.error}'),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                
                List<MessageModel> messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
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
                          'Henüz mesaj yok',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Bir mesaj göndererek sohbeti başlatın',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    MessageModel message = messages[index];
                    bool isMe = message.senderId == _auth.currentUser!.uid;
                    
                    // Mesajları tarih gruplarına ayır
                    bool showDate = false;
                    if (index == messages.length - 1) {
                      showDate = true;
                    } else {
                      final currentDate = DateFormat('yyyy-MM-dd').format(message.timestamp);
                      final previousDate = DateFormat('yyyy-MM-dd').format(messages[index + 1].timestamp);
                      showDate = currentDate != previousDate;
                    }
                    
                    return Column(
                      children: [
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getFormattedDate(message.timestamp),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        MessageBubble(
                          message: message.content,
                          isMe: isMe,
                          time: DateFormat('HH:mm').format(message.timestamp),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, -1),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Mesajınızı yazın...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: _isLoading 
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReceiverAvatar() {
    if (_receiver != null && _receiver!.profileImageUrl != null && _receiver!.profileImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CachedNetworkImage(
          imageUrl: _receiver!.profileImageUrl!,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => _buildDefaultAvatar(),
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }
  
  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 20,
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      child: Text(
        widget.receiverName.isNotEmpty ? widget.receiverName.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Bugün';
    } else if (dateToCheck == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('d MMMM yyyy', 'tr_TR').format(date);
    }
  }
  
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    String currentUserId = _auth.currentUser!.uid;
    
    try {
      MessageModel message = MessageModel(
        id: '',
        senderId: currentUserId,
        receiverId: widget.receiverId,
        content: _messageController.text.trim(),
        participants: [currentUserId, widget.receiverId],
        timestamp: DateTime.now(),
      );
      
      await _firestoreService.sendMessage(message);
      
      _messageController.clear();
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
