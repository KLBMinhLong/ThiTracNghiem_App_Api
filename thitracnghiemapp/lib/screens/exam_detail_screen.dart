import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/binh_luan.dart';
import '../models/de_thi.dart';
import '../providers/binh_luan_provider.dart';
import '../providers/de_thi_provider.dart';
import '../providers/chu_de_provider.dart';
import '../providers/thi_provider.dart';
import 'quiz_screen.dart';

class ExamDetailScreen extends StatefulWidget {
  final DeThi deThi;

  const ExamDetailScreen({super.key, required this.deThi});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _sendingComment = false;
  bool _startingQuiz = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.wait([
        _loadComments(),
        context.read<DeThiProvider>().fetchOpenDeThis(),
      ]);
      if (!mounted) {
        return;
      }
      final commentError = context.read<BinhLuanProvider>().error;
      final deThiError = context.read<DeThiProvider>().error;
      if (commentError != null) {
        _showToast(commentError);
      }
      if (deThiError != null) {
        _showToast(deThiError);
      }
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() {
    return context.read<BinhLuanProvider>().fetchComments(
      deThiId: widget.deThi.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.deThi;
    final topics = context.watch<ChuDeProvider>().chuDes;
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatFullDate(exam.ngayTao.toLocal());

    String topicName() {
      final nested = exam.chuDe?.tenChuDe;
      if (nested != null && nested.isNotEmpty) {
        return nested;
      }
      for (final topic in topics) {
        if (topic.id == exam.chuDeId) {
          return topic.tenChuDe;
        }
      }
      return 'Chưa có';
    }

    return Scaffold(
      appBar: AppBar(title: Text(exam.tenDeThi)),
      body: RefreshIndicator(
        onRefresh: _loadComments,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.tenDeThi,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          icon: Icons.category_outlined,
                          label: 'Chủ đề',
                          value: topicName(),
                        ),
                        _InfoChip(
                          icon: Icons.timer_outlined,
                          label: 'Thời gian',
                          value: '${exam.thoiGianThi} phút',
                        ),
                        _InfoChip(
                          icon: Icons.rule_outlined,
                          label: 'Số câu hỏi',
                          value: '${exam.soCauHoi}',
                        ),
                        _InfoChip(
                          icon: Icons.calendar_month_outlined,
                          label: 'Ngày tạo',
                          value: formattedDate,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: exam.isOpen && !_startingQuiz
                          ? _startQuiz
                          : null,
                      icon: _startingQuiz
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(exam.isOpen ? Icons.play_arrow : Icons.lock),
                      label: Text(
                        exam.isOpen
                            ? (_startingQuiz
                                  ? 'Đang chuẩn bị...'
                                  : 'Bắt đầu làm bài')
                            : 'Đề thi đã đóng',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Bình luận', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Consumer<BinhLuanProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.comments == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                final comments = provider.comments?.items ?? const <BinhLuan>[];
                if (comments.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: Text('Chưa có bình luận nào.')),
                  );
                }
                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final author = comment.taiKhoan;
                    return ListTile(
                      tileColor: Theme.of(context).colorScheme.surfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        author?.fullName ?? author?.userName ?? 'Ẩn danh',
                      ),
                      subtitle: Text(comment.noiDung),
                      trailing: Text(
                        MaterialLocalizations.of(
                          context,
                        ).formatShortDate(comment.ngayTao.toLocal()),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Chia sẻ cảm nhận của bạn...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                minLines: 1,
                maxLines: 3,
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: _sendingComment ? null : _submitComment,
              icon: _sendingComment
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startQuiz() async {
    FocusScope.of(context).unfocus();
    setState(() => _startingQuiz = true);
    final thiProvider = context.read<ThiProvider>();
    thiProvider.reset();
    await thiProvider.startThi(widget.deThi.id);
    if (!mounted) {
      return;
    }
    setState(() => _startingQuiz = false);
    final error = thiProvider.error;
    if (error != null) {
      final friendlyMessage = error.contains('SqlException')
          ? 'Không thể bắt đầu bài thi. Vui lòng thử lại sau.'
          : error;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyMessage)));
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => QuizScreen(deThi: widget.deThi)));
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      return;
    }
    setState(() => _sendingComment = true);
    final provider = context.read<BinhLuanProvider>();
    try {
      await provider.createComment(deThiId: widget.deThi.id, noiDung: content);
      final error = provider.error;
      if (error != null) {
        if (!mounted) {
          return;
        }
        _showToast(error);
        return;
      }
      await _loadComments();
      if (!mounted) {
        return;
      }
      _commentController.clear();
      _showToast('Đã đăng bình luận');
    } finally {
      if (mounted) {
        setState(() => _sendingComment = false);
      }
    }
  }

  void _showToast(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
