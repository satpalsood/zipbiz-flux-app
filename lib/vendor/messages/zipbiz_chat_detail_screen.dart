import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api/zipbiz_api_service.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';
import '../../models/user_model.dart';
import '../../widgets/common/zipbiz_header.dart';

class ZipBizChatDetailScreen extends StatefulWidget {
  final int recipientId;
  final String recipientName;
  final String? recipientAvatar;
  final int? listingId;
  final String? listingTitle;

  const ZipBizChatDetailScreen({
    super.key,
    required this.recipientId,
    required this.recipientName,
    this.recipientAvatar,
    this.listingId,
    this.listingTitle,
  });

  @override
  State<ZipBizChatDetailScreen> createState() => _ZipBizChatDetailScreenState();
}

class _ZipBizChatDetailScreenState extends State<ZipBizChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  List<Map<String, dynamic>> _messages = [];
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    // Poll every 10 seconds for new incoming messages
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchMessages(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    if (!silent) setState(() => _isLoading = true);

    try {
      final data = await ZipBizApiService().getMessageThread(
        user: user,
        recipientId: widget.recipientId,
      );

      final list = (data['messages'] as List? ?? [])
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();

      if (mounted) {
        setState(() {
          _messages = list;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted && !silent) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isSending = true);
    _messageController.clear();

    // Optimistic append
    final optimisticMsg = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'sender_id': int.tryParse(user.id ?? '0') ?? 0,
      'recipient_id': widget.recipientId,
      'listing_id': widget.listingId ?? 0,
      'message': text,
      'read_status': 0,
      'created_at': DateTime.now().toIso8601String(),
      'is_me': true,
    };

    setState(() {
      _messages.add(optimisticMsg);
    });
    _scrollToBottom();

    try {
      await ZipBizApiService().sendMessage(
        user: user,
        recipientId: widget.recipientId,
        message: text,
        listingId: widget.listingId ?? 0,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZipBizColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ZipBizColors.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: ZipBizColors.primaryContainer.withOpacity(0.15),
              backgroundImage: (widget.recipientAvatar != null && widget.recipientAvatar!.isNotEmpty)
                  ? NetworkImage(widget.recipientAvatar!)
                  : null,
              child: (widget.recipientAvatar == null || widget.recipientAvatar!.isEmpty)
                  ? Text(
                      widget.recipientName.isNotEmpty ? widget.recipientName[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: ZipBizColors.primaryContainer),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.recipientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZipBizTypography.labelLarge.copyWith(fontSize: 16),
                  ),
                  if (widget.listingTitle != null && widget.listingTitle!.isNotEmpty)
                    Text(
                      widget.listingTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: ZipBizColors.secondary, fontWeight: FontWeight.w600),
                    )
                  else
                    const Row(
                      children: [
                        Icon(Icons.circle, size: 7, color: ZipBizColors.statusOpen),
                        SizedBox(width: 4),
                        Text('Online on ZipBiz', style: TextStyle(fontSize: 11, color: ZipBizColors.statusOpen)),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: ZipBizColors.onSurface),
            onPressed: () => _fetchMessages(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: ZipBizColors.primaryContainer))
                : _messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('Start conversation with ${widget.recipientName}', style: ZipBizTypography.bodyMedium),
                            const SizedBox(height: 4),
                            Text('Inquire about service, availability, or quotes', style: ZipBizTypography.bodySmall),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _messages.length,
                        itemBuilder: (context, idx) {
                          final msg = _messages[idx];
                          final isMe = msg['is_me'] == true;
                          final text = msg['message']?.toString() ?? '';
                          final time = msg['created_at']?.toString() ?? '';
                          final formattedTime = time.contains(' ') ? time.split(' ')[1].substring(0, 5) : '';

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe ? ZipBizColors.primaryContainer : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                                  bottomRight: Radius.circular(isMe ? 4 : 16),
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
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: isMe ? Colors.white : ZipBizColors.onSurface,
                                    ),
                                  ),
                                  if (formattedTime.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          formattedTime,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isMe ? Colors.white70 : Colors.grey,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            (msg['read_status'] == 1) ? Icons.done_all : Icons.done,
                                            size: 13,
                                            color: (msg['read_status'] == 1) ? Colors.lightBlueAccent : Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFF0EDED))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: ZipBizColors.surfaceSubtle,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(fontSize: 14),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: ZipBizColors.primaryContainer,
                    radius: 20,
                    child: _isSending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 18),
                            onPressed: _sendMessage,
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
