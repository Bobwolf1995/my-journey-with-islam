import 'package:flutter/material.dart';

import '../../../shared/theme/app_colors.dart';
import '../data/chat_models.dart';
import '../data/chat_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    this.initialConversation,
  });

  final ConversationSummary? initialConversation;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late Future<MessagesResult> _messagesFuture;

  ConversationSummary? _conversation;
  List<ChatMessage> _messages = <ChatMessage>[];
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<MessagesResult> _loadChat() async {
    try {
      final selectedConversation = widget.initialConversation;

      if (selectedConversation != null && selectedConversation.id > 0) {
        _conversation = selectedConversation;

        final messagesResult =
            await _chatService.getMessages(selectedConversation.id);

        _messages = messagesResult.messages;
        _errorMessage = messagesResult.isFromServer
            ? null
            : 'يتم عرض محادثة تجريبية لحين الاتصال بالسيرفر.';
        _scrollToBottom();

        return messagesResult;
      }

      final conversationsResult = await _chatService.getConversations();

      final conversation = conversationsResult.conversations.isNotEmpty
          ? conversationsResult.conversations.first
          : ConversationsResult.fallback().conversations.first;

      _conversation = conversation;

      if (!conversationsResult.isFromServer) {
        final fallback = MessagesResult.fallback();
        _messages = fallback.messages;
        _errorMessage = 'يتم عرض محادثة تجريبية لحين الاتصال بالسيرفر.';
        _scrollToBottom();
        return fallback;
      }

      final messagesResult = await _chatService.getMessages(conversation.id);
      _messages = messagesResult.messages;
      _errorMessage = messagesResult.isFromServer
          ? null
          : 'يتم عرض محادثة تجريبية لحين الاتصال بالسيرفر.';
      _scrollToBottom();

      return messagesResult;
    } catch (_) {
      final fallback = MessagesResult.fallback();
      _conversation = widget.initialConversation ??
          ConversationsResult.fallback().conversations.first;
      _messages = fallback.messages;
      _errorMessage = 'تعذر تحميل المحادثة الآن. حاول مرة أخرى.';
      _scrollToBottom();
      return fallback;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _messagesFuture = _loadChat();
    });

    await _messagesFuture;
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) {
      return;
    }

    final conversation = _conversation;

    if (conversation == null || conversation.id <= 0) {
      setState(() {
        _errorMessage = 'لا توجد محادثة متاحة الآن.';
      });
      return;
    }

    _messageController.clear();

    final localMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: -1,
      senderName: 'أنت',
      body: text,
      messageType: 'text',
      createdAt: '',
    );

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _messages = [..._messages, localMessage];
    });

    _scrollToBottom();

    final sentMessage = await _chatService.sendMessage(
      conversationId: conversation.id,
      body: text,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSending = false;

      if (sentMessage == null) {
        _errorMessage = 'تم عرض الرسالة محليًا، لكن تعذر إرسالها للسيرفر.';
      }
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isMine(ChatMessage message) {
    return message.senderId == -1 || message.senderName == 'أنت';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: FutureBuilder<MessagesResult>(
            future: _messagesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingView();
              }

              final conversation = _conversation ??
                  ConversationsResult.fallback().conversations.first;

              return Column(
                children: [
                  _ChatHeader(conversation: conversation),
                  if (_errorMessage != null)
                    _ConnectionNotice(message: _errorMessage!),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      onRefresh: _refresh,
                      child: _messages.isEmpty
                          ? const _EmptyMessages()
                          : ListView.separated(
                              controller: _scrollController,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding:
                                  const EdgeInsets.fromLTRB(18, 16, 18, 22),
                              itemCount: _messages.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 10);
                              },
                              itemBuilder: (context, index) {
                                final message = _messages[index];

                                return _MessageBubble(
                                  message: message,
                                  isMine: _isMine(message),
                                );
                              },
                            ),
                    ),
                  ),
                  _MessageComposer(
                    controller: _messageController,
                    isSending: _isSending,
                    onSend: _sendMessage,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.conversation,
  });

  final ConversationSummary conversation;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(19),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conversation.title,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _OnlineDot(),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'متاح للمساعدة والتوجيه',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CircleButton(
            icon: Icons.arrow_forward_ios_rounded,
            onTap: () {
              Navigator.maybePop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _ConnectionNotice extends StatelessWidget {
  const _ConnectionNotice({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.warning,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMine,
  });

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 315),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMine ? 6 : 20),
            bottomRight: Radius.circular(isMine ? 20 : 6),
          ),
          border: isMine ? null : Border.all(color: AppColors.borderSoft),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 14,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isMine && message.senderName.isNotEmpty) ...[
              Text(
                message.senderName,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
            ],
            Text(
              message.body,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isMine ? Colors.white : AppColors.text,
                fontSize: 14,
                height: 1.58,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        14 + MediaQuery.viewInsetsOf(context).bottom * 0,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSoft),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 18,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Material(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: isSending ? null : onSend,
              child: SizedBox(
                width: 50,
                height: 50,
                child: isSending
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 23,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textAlign: TextAlign.right,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (!isSending) {
                  onSend();
                }
              },
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
                filled: true,
                fillColor: AppColors.surfaceSoft,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.borderSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 110),
        Container(
          width: 76,
          height: 76,
          margin: const EdgeInsets.symmetric(horizontal: 110),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: AppColors.primary,
            size: 40,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'لا توجد رسائل بعد',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.text,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'ابدأ المحادثة بسؤال قصير وسيظهر الرد هنا.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
        strokeWidth: 2.6,
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    this.onTap,
  });

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Icon(
            icon,
            color: AppColors.text,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
    );
  }
}
