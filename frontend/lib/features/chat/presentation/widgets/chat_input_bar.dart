import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Question input pinned to the bottom of the chat.
///
/// Disabled while an answer is pending: the backend handles one question per
/// conversation at a time, and queueing a second would interleave two RAG runs
/// in the same history.
class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.enabled,
    required this.onSubmit,
  });

  final bool enabled;
  final ValueChanged<String> onSubmit;

  /// Matches the backend's `askSchema` limit.
  static const maxQuestionLength = 2000;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  bool get _canSend => widget.enabled && _controller.text.trim().isNotEmpty;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSend) return;

    final question = _controller.text.trim();
    _controller.clear();
    widget.onSubmit(question);

    // Keep focus so the next question can be typed straight away.
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: ChatInputBar.maxQuestionLength,
                  textInputAction: TextInputAction.send,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(
                      ChatInputBar.maxQuestionLength,
                    ),
                  ],
                  decoration: InputDecoration(
                    hintText: widget.enabled
                        ? 'Tanyakan sesuatu tentang dokumen perusahaan…'
                        : 'Menunggu jawaban…',
                    // The counter only matters near the limit; hide it
                    // otherwise so the bar stays compact.
                    counterText:
                        _controller.text.length >
                            ChatInputBar.maxQuestionLength - 200
                        ? null
                        : '',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: IconButton.filled(
                  onPressed: _canSend ? _submit : null,
                  icon: const Icon(Icons.send),
                  tooltip: 'Kirim',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
