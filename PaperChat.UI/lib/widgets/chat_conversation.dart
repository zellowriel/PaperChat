import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../core/api_client.dart';
import '../models/api_models.dart';
import 'common.dart';

class ChatConversation extends StatefulWidget {
  const ChatConversation({
    super.key,
    required this.controller,
    required this.document,
    this.quote,
    this.compact = false,
    this.onCitationTap,
  });

  final AppController controller;
  final PaperDocument document;
  final String? quote;
  final bool compact;
  final ValueChanged<int>? onCitationTap;

  @override
  State<ChatConversation> createState() => _ChatConversationState();
}

class _ChatConversationState extends State<ChatConversation> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loadingHistory = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void didUpdateWidget(covariant ChatConversation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document.id != widget.document.id) {
      _messages.clear();
      _loadHistory();
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loadingHistory = true;
      _error = null;
    });
    try {
      final history = await widget.controller.api.getChatHistory(widget.document.id);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(history);
        _loadingHistory = false;
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingHistory = false;
        _error = error.message;
      });
    }
  }

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _sending) return;
    _input.clear();
    setState(() {
      _sending = true;
      _error = null;
      _messages.add(
        ChatMessage(
          id: 'local-${DateTime.now().microsecondsSinceEpoch}',
          senderRole: 'USER',
          content: question,
          quoteReference: widget.quote,
          createdAt: DateTime.now(),
        ),
      );
    });
    _scrollToBottom();

    try {
      final result = await widget.controller.api.sendChat(
        documentId: widget.document.id,
        question: question,
        quote: widget.quote,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            id: 'local-ai-${DateTime.now().microsecondsSinceEpoch}',
            senderRole: 'AI',
            content: result.answer,
            citationPage: result.citationPage,
            createdAt: result.createdAt ?? DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.quote != null && widget.quote!.trim().isNotEmpty)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lavender,
              borderRadius: BorderRadius.circular(10),
              border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
            ),
            child: Text(
              '“${widget.quote}”',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontFamily: 'serif', fontStyle: FontStyle.italic),
            ),
          ),
        Expanded(
          child: _loadingHistory
              ? const Center(child: CircularProgressIndicator())
              : _messages.isEmpty
                  ? EmptyState(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Bắt đầu hỏi về tài liệu',
                      subtitle:
                          'Đặt câu hỏi về phương pháp, công thức hoặc nội dung trong “${widget.document.title}”.',
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                      itemCount: _messages.length + (_sending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_sending && index == _messages.length) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          );
                        }
                        return _MessageBubble(
                          message: _messages[index],
                          onCitationTap: widget.onCitationTap,
                        );
                      },
                    ),
        ),
        if (_error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: const Color(0xFFFFE9E9),
            child: Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              widget.compact ? 12 : 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi về tài liệu...',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.onCitationTap});

  final ChatMessage message;
  final ValueChanged<int>? onCitationTap;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final color = isUser ? AppColors.primary : Theme.of(context).cardColor;
    final textColor = isUser ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(15),
              topRight: const Radius.circular(15),
              bottomLeft: Radius.circular(isUser ? 15 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 15),
            ),
            border: isUser ? null : Border.all(color: AppColors.line),
            boxShadow: isUser
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x08111B35),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 14, color: AppColors.primary),
                      SizedBox(width: 5),
                      Text(
                        'PaperChat AI',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              if (message.quoteReference != null && isUser)
                Text(
                  'Trích dẫn: ${message.quoteReference}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.75),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              SelectableText(
                message.content,
                style: TextStyle(
                  color: textColor,
                  height: 1.48,
                  fontSize: 14,
                ),
              ),
              if (!isUser && message.citationPage != null) ...[
                const SizedBox(height: 9),
                InkWell(
                  onTap: onCitationTap == null
                      ? null
                      : () => onCitationTap!(message.citationPage!),
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBlue,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.link_rounded,
                          size: 13,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Trích dẫn: Trang ${message.citationPage}',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
