import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ket_qua_thi.dart';
import '../providers/chat_provider.dart';

class ResultReviewScreen extends StatelessWidget {
  final KetQuaThiDetail detail;
  const ResultReviewScreen({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final title = detail.deThi?.tenDeThi ?? 'Xem kết quả thi';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Chat với AI',
            icon: const Icon(Icons.smart_toy_outlined),
            onPressed: () => _openChat(context),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: detail.chiTiet.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = detail.chiTiet[index];
          final selected = item.dapAnChon?.toUpperCase();
          final correct = item.dapAnDung.toUpperCase();
          final isCorrect = item.dungHaySai == true;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Câu ${index + 1} • ${isCorrect ? 'Đúng' : 'Sai'}',
                          style: TextStyle(
                            color: isCorrect
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (selected != null)
                        Text(
                          'Bạn chọn: $selected',
                          style: const TextStyle(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.noiDung,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _AnswerTile(
                    label: 'A',
                    text: item.dapAnA,
                    selected: selected == 'A',
                    correct: correct == 'A',
                  ),
                  _AnswerTile(
                    label: 'B',
                    text: item.dapAnB,
                    selected: selected == 'B',
                    correct: correct == 'B',
                  ),
                  if (item.dapAnC != null && item.dapAnC!.isNotEmpty)
                    _AnswerTile(
                      label: 'C',
                      text: item.dapAnC!,
                      selected: selected == 'C',
                      correct: correct == 'C',
                    ),
                  if (item.dapAnD != null && item.dapAnD!.isNotEmpty)
                    _AnswerTile(
                      label: 'D',
                      text: item.dapAnD!,
                      selected: selected == 'D',
                      correct: correct == 'D',
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openChat(context),
        icon: const Icon(Icons.smart_toy_outlined),
        label: const Text('Chat với AI'),
      ),
    );
  }

  void _openChat(BuildContext context) {
    final chat = context.read<ChatProvider>();
    chat.setContext(ketQuaThiId: detail.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) =>
          ChangeNotifierProvider.value(value: chat, child: const _ChatSheet()),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final bool correct;
  const _AnswerTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.correct,
  });

  @override
  Widget build(BuildContext context) {
    Color? color;
    IconData? icon;
    if (correct) {
      color = Colors.green;
      icon = Icons.check_circle_outline;
    } else if (selected) {
      color = Colors.red;
      icon = Icons.cancel_outlined;
    }
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 12,
        backgroundColor: color?.withOpacity(0.1),
        child: Text(label, style: TextStyle(color: color ?? Colors.grey[800])),
      ),
      title: Text(text),
      trailing: icon == null ? null : Icon(icon, color: color),
    );
  }
}

class _ChatSheet extends StatefulWidget {
  const _ChatSheet();

  @override
  State<_ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<_ChatSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) => Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hỏi AI về đề thi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(12),
                  itemCount: chat.messages.length,
                  itemBuilder: (context, index) {
                    final m = chat.messages[index];
                    final isUser = m.role == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 560),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isUser
                              ? Colors.blue.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(m.content),
                      ),
                    );
                  },
                ),
              ),
              if (chat.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    chat.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Nhập câu hỏi...',
                        ),
                        onSubmitted: (_) => _send(chat),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: chat.sending
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      onPressed: chat.sending ? null : () => _send(chat),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _send(ChatProvider chat) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    chat.send(text);
  }
}
