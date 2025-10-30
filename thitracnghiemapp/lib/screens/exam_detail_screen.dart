import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/binh_luan.dart';
import '../models/de_thi.dart';
import '../providers/auth_provider.dart';
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
                    final authUser = context.read<AuthProvider>().currentUser;
                    final isOwner =
                        (comment.taiKhoan?.id ?? comment.taiKhoanId) ==
                        authUser?.id;
                    return ListTile(
                      tileColor: Theme.of(context).colorScheme.surfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        author?.fullName ?? author?.userName ?? 'Ẩn danh',
                      ),
                      subtitle: Text(comment.noiDung),
                      trailing: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            MaterialLocalizations.of(
                              context,
                            ).formatShortDate(comment.ngayTao.toLocal()),
                          ),
                          if (isOwner)
                            PopupMenuButton<String>(
                              tooltip: 'Tuỳ chọn',
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditComment(comment);
                                } else if (value == 'delete') {
                                  _confirmDeleteComment(comment);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Sửa'),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline),
                                    title: Text('Xoá'),
                                  ),
                                ),
                              ],
                            ),
                        ],
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
      _showToast('Vui lòng nhập nội dung bình luận');
      return;
    }
    if (content.length < 5) {
      _showToast('Nội dung bình luận tối thiểu 5 ký tự');
      return;
    }
    if (content.length > 500) {
      _showToast('Nội dung bình luận tối đa 500 ký tự');
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
        final friendly = error.toLowerCase().contains('validation')
            ? 'Nội dung bình luận không hợp lệ. (tối thiểu 5, tối đa 500 ký tự)'
            : error;
        _showToast(friendly);
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

  Future<void> _showEditComment(BinhLuan comment) async {
    final provider = context.read<BinhLuanProvider>();
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: comment.noiDung);

    final updatedText = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: viewInsets.bottom + 24,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controller,
                      decoration: const InputDecoration(
                        labelText: 'Chỉnh sửa bình luận',
                      ),
                      minLines: 2,
                      maxLines: 6,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Vui lòng nhập nội dung';
                        if (text.length < 5) return 'Tối thiểu 5 ký tự';
                        if (text.length > 500) return 'Tối đa 500 ký tự';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        FocusScope.of(sheetContext).unfocus();
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop(controller.text.trim());
                      },
                      child: const Text('Lưu'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (updatedText == null) return;
    await provider.updateComment(id: comment.id, noiDung: updatedText);
    final error = provider.error;
    if (error != null) {
      _showToast(error);
      return;
    }
    _showToast('Đã cập nhật bình luận');
  }

  Future<void> _confirmDeleteComment(BinhLuan comment) async {
    final provider = context.read<BinhLuanProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xoá bình luận'),
        content: const Text('Bạn có chắc muốn xoá bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await provider.deleteComment(comment.id);
    final error = provider.error;
    if (error != null) {
      _showToast(error);
      return;
    }
    _showToast('Đã xoá bình luận');
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
