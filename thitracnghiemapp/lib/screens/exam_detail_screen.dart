import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/binh_luan.dart';
import '../models/de_thi.dart';
import '../providers/auth_provider.dart';
import '../providers/binh_luan_provider.dart';
import '../providers/de_thi_provider.dart';
import '../providers/chu_de_provider.dart';
import '../providers/thi_provider.dart';
import '../utils/ui_helpers.dart';
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
        UIHelpers.showErrorSnackBar(context, commentError);
      }
      if (deThiError != null) {
        UIHelpers.showErrorSnackBar(context, deThiError);
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
    final formattedDate = UIHelpers.formatDateVN(exam.ngayTao.toLocal());
    final theme = Theme.of(context);

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
      return 'Chưa cập nhật';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(exam.tenDeThi), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: _loadComments,
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Exam Info Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with icon
                    Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.quiz,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        UIHelpers.horizontalSpaceMedium(),
                        Expanded(
                          child: Text(
                            exam.tenDeThi,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                    UIHelpers.verticalSpaceLarge(),

                    // Info Grid
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.category_outlined,
                            label: 'Chủ đề',
                            value: topicName(),
                            color: Colors.purple,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.timer_outlined,
                            label: 'Thời gian',
                            value: '${exam.thoiGianThi} phút',
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.rule_outlined,
                            label: 'Số câu',
                            value: '${exam.soCauHoi}',
                            color: Colors.green,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.calendar_month_outlined,
                            label: 'Ngày tạo',
                            value: formattedDate.split(' ')[0], // Only date
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    UIHelpers.verticalSpaceLarge(),

                    // Start Button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: exam.isOpen && !_startingQuiz
                            ? _startQuiz
                            : null,
                        icon: _startingQuiz
                            ? SizedBox(
                                width: 18.w,
                                height: 18.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.w,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                exam.isOpen ? Icons.play_arrow : Icons.lock,
                                size: 20.sp,
                              ),
                        label: Text(
                          exam.isOpen
                              ? (_startingQuiz
                                    ? 'Đang chuẩn bị...'
                                    : 'Bắt đầu làm bài')
                              : 'Đề thi đã đóng',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            UIHelpers.verticalSpaceLarge(),

            // Comments Section
            Row(
              children: [
                Icon(
                  Icons.comment_outlined,
                  size: 20.sp,
                  color: theme.colorScheme.primary,
                ),
                UIHelpers.horizontalSpaceSmall(),
                Text(
                  'Bình luận',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
            UIHelpers.verticalSpaceMedium(),

            Consumer<BinhLuanProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.comments == null) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.h),
                    child: Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(strokeWidth: 3.w),
                          UIHelpers.verticalSpaceSmall(),
                          Text(
                            'Đang tải bình luận...',
                            style: TextStyle(fontSize: 13.sp),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final comments = provider.comments?.items ?? const <BinhLuan>[];
                if (comments.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.comment_outlined,
                    message:
                        'Chưa có bình luận nào.\nHãy là người đầu tiên bình luận!',
                  );
                }

                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final author = comment.taiKhoan;
                    final authUser = context.read<AuthProvider>().currentUser;
                    final isOwner =
                        (comment.taiKhoan?.id ?? comment.taiKhoanId) ==
                        authUser?.id;

                    final authorName = author?.fullName.isNotEmpty == true
                        ? author!.fullName
                        : (author?.userName ?? 'Ẩn danh');
                    final initial = authorName[0].toUpperCase();

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 20.r,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              child: Text(
                                initial,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            UIHelpers.horizontalSpaceMedium(),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          authorName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        UIHelpers.formatDateVN(
                                          comment.ngayTao.toLocal(),
                                        ),
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    comment.noiDung,
                                    style: TextStyle(fontSize: 13.sp),
                                  ),
                                ],
                              ),
                            ),

                            // Menu for owner
                            if (isOwner) ...[
                              UIHelpers.horizontalSpaceSmall(),
                              PopupMenuButton<String>(
                                tooltip: 'Tuỳ chọn',
                                icon: Icon(Icons.more_vert, size: 20.sp),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditComment(comment);
                                  } else if (value == 'delete') {
                                    _confirmDeleteComment(comment);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_outlined, size: 20.sp),
                                        UIHelpers.horizontalSpaceSmall(),
                                        const Text('Sửa'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_outline, size: 20.sp),
                                        UIHelpers.horizontalSpaceSmall(),
                                        const Text('Xóa'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            SizedBox(height: 100.h), // Space for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        child: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10.r,
                offset: Offset(0, -2.h),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Chia sẻ cảm nhận của bạn...',
                    hintStyle: TextStyle(fontSize: 14.sp),
                    prefixIcon: Icon(Icons.mode_comment_outlined, size: 20.sp),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 3,
                ),
              ),
              UIHelpers.horizontalSpaceMedium(),
              Container(
                width: 48.w,
                height: 48.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: IconButton(
                  onPressed: _sendingComment ? null : _submitComment,
                  icon: _sendingComment
                      ? SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.w,
                            color: Colors.white,
                          ),
                        )
                      : Icon(Icons.send, color: Colors.white, size: 20.sp),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
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
    if (!mounted) return;

    setState(() => _startingQuiz = false);
    final error = thiProvider.error;
    if (error != null) {
      final friendlyMessage = error.contains('SqlException')
          ? 'Không thể bắt đầu bài thi. Vui lòng thử lại sau.'
          : error;
      UIHelpers.showErrorSnackBar(context, friendlyMessage);
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => QuizScreen(deThi: widget.deThi)));
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) {
      UIHelpers.showInfoSnackBar(context, 'Vui lòng nhập nội dung bình luận');
      return;
    }
    if (content.length < 5) {
      UIHelpers.showInfoSnackBar(
        context,
        'Nội dung bình luận tối thiểu 5 ký tự',
      );
      return;
    }
    if (content.length > 500) {
      UIHelpers.showInfoSnackBar(
        context,
        'Nội dung bình luận tối đa 500 ký tự',
      );
      return;
    }

    setState(() => _sendingComment = true);
    final provider = context.read<BinhLuanProvider>();
    try {
      await provider.createComment(deThiId: widget.deThi.id, noiDung: content);
      final error = provider.error;
      if (error != null) {
        if (!mounted) return;
        final friendly = error.toLowerCase().contains('validation')
            ? 'Nội dung bình luận không hợp lệ. (tối thiểu 5, tối đa 500 ký tự)'
            : error;
        UIHelpers.showErrorSnackBar(context, friendly);
        return;
      }
      await _loadComments();
      if (!mounted) return;
      _commentController.clear();
      UIHelpers.showSuccessSnackBar(context, 'Đã đăng bình luận');
    } finally {
      if (mounted) {
        setState(() => _sendingComment = false);
      }
    }
  }

  Future<void> _showEditComment(BinhLuan comment) async {
    final theme = Theme.of(context);
    final provider = context.read<BinhLuanProvider>();
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController(text: comment.noiDung);

    final updatedText = await showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        final viewInsets = MediaQuery.of(sheetContext).viewInsets;
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: viewInsets.bottom + 16.h,
              left: 16.w,
              right: 16.w,
              top: 16.h,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 24.sp,
                          ),
                        ),
                        UIHelpers.horizontalSpaceMedium(),
                        Text(
                          'Chỉnh sửa bình luận',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp,
                          ),
                        ),
                      ],
                    ),
                    UIHelpers.verticalSpaceMedium(),

                    TextFormField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: 'Nội dung',
                        hintText: 'Nhập nội dung bình luận',
                        prefixIcon: Icon(
                          Icons.mode_comment_outlined,
                          size: 20.sp,
                        ),
                        alignLabelWithHint: true,
                      ),
                      minLines: 3,
                      maxLines: 6,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) return 'Vui lòng nhập nội dung';
                        if (text.length < 5) return 'Tối thiểu 5 ký tự';
                        if (text.length > 500) return 'Tối đa 500 ký tự';
                        return null;
                      },
                    ),
                    UIHelpers.verticalSpaceLarge(),

                    FilledButton.icon(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        FocusScope.of(sheetContext).unfocus();
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop(controller.text.trim());
                      },
                      icon: Icon(Icons.check, size: 20.sp),
                      label: const Text('Lưu'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                    ),
                    UIHelpers.verticalSpaceSmall(),

                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Hủy'),
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

    UIHelpers.showLoadingDialog(context);
    await provider.updateComment(id: comment.id, noiDung: updatedText);

    if (mounted) Navigator.pop(context); // Close loading

    final error = provider.error;
    if (error != null && mounted) {
      UIHelpers.showErrorSnackBar(context, error);
      return;
    }

    if (mounted) {
      UIHelpers.showSuccessSnackBar(context, 'Đã cập nhật bình luận');
    }
  }

  Future<void> _confirmDeleteComment(BinhLuan comment) async {
    final provider = context.read<BinhLuanProvider>();
    final confirm = await UIHelpers.showConfirmDialog(
      context,
      title: 'Xóa bình luận',
      message: 'Bạn có chắc muốn xóa bình luận này?',
      confirmText: 'Xóa',
      cancelText: 'Hủy',
      isDangerous: true,
    );

    if (confirm != true) return;

    UIHelpers.showLoadingDialog(context);
    await provider.deleteComment(comment.id);

    if (mounted) Navigator.pop(context); // Close loading

    final error = provider.error;
    if (error != null && mounted) {
      UIHelpers.showErrorSnackBar(context, error);
      return;
    }

    if (mounted) {
      UIHelpers.showSuccessSnackBar(context, 'Đã xóa bình luận');
    }
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20.sp, color: color),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
