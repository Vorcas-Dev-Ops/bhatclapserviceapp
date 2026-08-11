import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:partner_app/providers/api_providers.dart';

class PartnerChatScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String? customerName;

  const PartnerChatScreen({
    super.key,
    required this.bookingId,
    this.customerName,
  });

  @override
  ConsumerState<PartnerChatScreen> createState() => _PartnerChatScreenState();
}

class _PartnerChatScreenState extends ConsumerState<PartnerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Timer? _chatTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _chatTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadMessages(showLoading: false);
    });
  }

  @override
  void dispose() {
    _chatTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (showLoading && _messages.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final apiClient = ref.read(apiClientProvider);
      final rawId = widget.bookingId.replaceAll('CHAT-BKG-', '');
      final convId = 'CHAT-BKG-$rawId';

      List<dynamic> fetchedMessages = [];

      try {
        final res = await apiClient.dio.get('/api/chat/conversations/$convId/messages');
        if (res.statusCode == 200 || res.statusCode == 201) {
          final body = res.data;
          final payload = body['data'] ?? body;
          if (payload is Map && payload['messages'] is List) {
            fetchedMessages = payload['messages'];
          } else if (payload is List) {
            fetchedMessages = payload;
          }
        }
      } catch (_) {}

      if (fetchedMessages.isEmpty) {
        try {
          final res = await apiClient.dio.get('/api/chat/conversations', queryParameters: {
            'booking_id': rawId,
          });
          if (res.statusCode == 200) {
            final body = res.data;
            final payload = body['data'] ?? body;
            if (payload is List && payload.isNotEmpty) {
              final conv = payload.first;
              final actualConvId = conv['conversation_id'] ?? conv['_id'];
              if (actualConvId != null) {
                final msgRes = await apiClient.dio.get('/api/chat/conversations/$actualConvId/messages');
                if (msgRes.statusCode == 200) {
                  final msgBody = msgRes.data;
                  final msgPayload = msgBody['data'] ?? msgBody;
                  fetchedMessages = msgPayload['messages'] ?? msgPayload ?? [];
                }
              }
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages = fetchedMessages;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final apiClient = ref.read(apiClientProvider);
      final rawId = widget.bookingId.replaceAll('CHAT-BKG-', '');
      final convId = 'CHAT-BKG-$rawId';

      final res = await apiClient.dio.post('/api/chat/conversations/$convId/messages', data: {
        'bookingId': rawId,
        'text': text,
      });

      if (mounted) {
        setState(() => _isSending = false);
        if (res.statusCode == 200 || res.statusCode == 201) {
          _loadMessages(showLoading: false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customerName ?? 'Customer',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16155D),
              ),
            ),
            Text(
              'Booking #${widget.bookingId.substring(widget.bookingId.length > 6 ? widget.bookingId.length - 6 : 0)}',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF16155D)),
            onPressed: () => _loadMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(
                        child: Text(
                          'No messages yet. Chat with your customer here.',
                          style: TextStyle(color: Colors.black45, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final senderRole = msg['sender_role'] ?? msg['role'] ?? 'provider';
                          final isProvider = senderRole == 'provider';
                          final text = msg['text'] ?? msg['message'] ?? '';
                          final timeStr = msg['createdAt'] != null
                              ? DateTime.parse(msg['createdAt']).toLocal().toString().substring(11, 16)
                              : '';

                          return Align(
                            alignment: isProvider ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isProvider ? const Color(0xFF16155D) : Colors.white,
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isProvider ? const Radius.circular(0) : const Radius.circular(16),
                                  bottomLeft: isProvider ? const Radius.circular(16) : const Radius.circular(0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isProvider ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: isProvider ? Colors.white : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (timeStr.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: isProvider ? Colors.white70 : Colors.black38,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Chat Input Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type message for customer...',
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
                        fillColor: const Color(0xFFF5F6FA),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFF16155D),
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
