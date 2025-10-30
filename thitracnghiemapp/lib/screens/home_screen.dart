import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart' as qr;

import '../models/de_thi.dart';
import '../models/ket_qua_thi.dart';
import '../models/lien_he.dart';
import '../providers/auth_provider.dart';
import '../providers/chu_de_provider.dart';
import '../providers/de_thi_provider.dart';
import '../providers/ket_qua_thi_provider.dart';
import '../providers/lien_he_provider.dart';
import '../utils/ui_helpers.dart';
import 'admin/admin_dashboard_screen.dart';
import 'exam_detail_screen.dart';
import 'login_screen.dart';
import 'result_review_screen.dart';
import 'statistics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentTab = 0;
  int? _selectedChuDeId;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final auth = context.read<AuthProvider>();
    final onlyUserId = auth.currentUser?.id;
    try {
      await Future.wait([
        context.read<DeThiProvider>().fetchOpenDeThis(),
        context.read<ChuDeProvider>().fetchChuDes(),
        context.read<KetQuaThiProvider>().fetchKetQuaThiList(
          onlyUserId: onlyUserId,
        ),
        context.read<LienHeProvider>().fetchMine(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  void _disposeTextControllers(List<TextEditingController> controllers) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final controller in controllers) {
        controller.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final titles = [
      'Danh sách đề thi',
      'Lịch sử làm bài',
      'Góp ý & Hỗ trợ',
      'Tài khoản của tôi',
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(titles[_currentTab]),
        centerTitle: false,
        actions: [
          if (auth.isAdmin)
            IconButton(
              tooltip: 'Quản trị',
              icon: Icon(Icons.admin_panel_settings_outlined, size: 22.sp),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
        ],
      ),
      body: _initializing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(strokeWidth: 3.w),
                  UIHelpers.verticalSpaceMedium(),
                  Text(
                    'Đang tải dữ liệu...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : IndexedStack(
              index: _currentTab,
              children: [
                _ExamTab(
                  searchController: _searchController,
                  selectedChuDeId: _selectedChuDeId,
                  onTopicSelected: (id) =>
                      setState(() => _selectedChuDeId = id),
                  onOpenExam: (deThi) => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExamDetailScreen(deThi: deThi),
                    ),
                  ),
                ),
                _HistoryTab(
                  onViewDetail: _openResultReview,
                  restrictToUserId: auth.currentUser?.id,
                ),
                _ContactTab(onCreate: _showCreateContact),
                _ProfileTab(
                  onEditProfile: _showEditProfile,
                  onChangePassword: _showChangePassword,
                  onLogout: _confirmLogout,
                ),
              ],
            ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) => setState(() => _currentTab = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined, size: 24.sp),
            selectedIcon: Icon(Icons.quiz, size: 24.sp),
            label: 'Đề thi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined, size: 24.sp),
            selectedIcon: Icon(Icons.history, size: 24.sp),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.feedback_outlined, size: 24.sp),
            selectedIcon: Icon(Icons.feedback, size: 24.sp),
            label: 'Góp ý',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline, size: 24.sp),
            selectedIcon: Icon(Icons.person, size: 24.sp),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext dialogContext) async {
    final shouldLogout = await UIHelpers.showConfirmDialog(
      dialogContext,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?',
      confirmText: 'Đăng xuất',
      cancelText: 'Hủy',
      isDangerous: true,
    );

    if (shouldLogout != true) return;

    await dialogContext.read<AuthProvider>().logout();
    if (!mounted) return;

    Navigator.of(dialogContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget? _buildFab() {
    if (_currentTab == 2) {
      return FloatingActionButton.extended(
        onPressed: () => _showCreateContact(context),
        icon: Icon(Icons.add_comment_outlined, size: 20.sp),
        label: Text(
          'Gửi góp ý',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      );
    }
    return null;
  }

  Future<void> _openResultReview(KetQuaThiSummary summary) async {
    final provider = context.read<KetQuaThiProvider>();
    await provider.fetchKetQuaThi(summary.id);
    final detail = provider.selectedKetQuaThi;
    if (!mounted || detail == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultReviewScreen(detail: detail)),
    );
    provider.clearSelected();
  }

  Future<void> _showCreateContact(BuildContext context) async {
    final theme = Theme.of(context);
    final lienHeProvider = context.read<LienHeProvider>();
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final hostContext = context;

    try {
      final formResult = await showModalBottomSheet<_ContactFormResult?>(
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
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
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
                              Icons.feedback_outlined,
                              color: Colors.white,
                              size: 24.sp,
                            ),
                          ),
                          UIHelpers.horizontalSpaceMedium(),
                          Text(
                            'Gửi góp ý mới',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 18.sp,
                            ),
                          ),
                        ],
                      ),
                      UIHelpers.verticalSpaceMedium(),

                      // Title Field
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề',
                          hintText: 'Nhập tiêu đề góp ý',
                          prefixIcon: Icon(Icons.title, size: 20.sp),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập tiêu đề'
                            : null,
                      ),
                      UIHelpers.verticalSpaceMedium(),

                      // Content Field
                      TextFormField(
                        controller: contentController,
                        decoration: InputDecoration(
                          labelText: 'Nội dung',
                          hintText: 'Nhập nội dung góp ý chi tiết',
                          prefixIcon: Icon(
                            Icons.description_outlined,
                            size: 20.sp,
                          ),
                          alignLabelWithHint: true,
                        ),
                        minLines: 4,
                        maxLines: 8,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập nội dung'
                            : null,
                      ),
                      UIHelpers.verticalSpaceLarge(),

                      // Submit Button
                      FilledButton.icon(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          FocusScope.of(sheetContext).unfocus();
                          if (!sheetContext.mounted) {
                            return;
                          }
                          Navigator.of(sheetContext).pop(
                            _ContactFormResult(
                              title: titleController.text.trim(),
                              content: contentController.text.trim(),
                            ),
                          );
                        },
                        icon: Icon(Icons.send, size: 20.sp),
                        label: const Text('Gửi góp ý'),
                        style: FilledButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                      ),
                      UIHelpers.verticalSpaceSmall(),

                      // Cancel Button
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

      if (!mounted || formResult == null) {
        return;
      }

      await Future<void>.delayed(Duration.zero);
      if (!mounted) {
        return;
      }

      UIHelpers.showLoadingDialog(hostContext);
      await lienHeProvider.createLienHe(
        tieuDe: formResult.title,
        noiDung: formResult.content,
      );

      if (!mounted) {
        return;
      }

      Navigator.pop(hostContext); // Close loading

      final error = lienHeProvider.error;
      if (error != null) {
        UIHelpers.showErrorSnackBar(hostContext, error);
        return;
      }
      UIHelpers.showSuccessSnackBar(hostContext, 'Đã gửi góp ý thành công');
    } finally {
      titleController.dispose();
      contentController.dispose();
    }
  }

  Future<void> _showEditProfile(BuildContext context) async {
    final rootContext = context;
    final auth = rootContext.read<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      return;
    }

    final success = await showModalBottomSheet<bool>(
      context: rootContext,
      isScrollControlled: true,
      builder: (_) => _EditProfileSheet(
        fullName: user.fullName,
        email: user.email,
        phone: user.phoneNumber,
        birthday: user.birthday,
        gender: user.gender,
      ),
    );

    if (success == true && mounted) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công')),
      );
    }
  }

  Future<void> _showChangePassword(BuildContext context) async {
    final rootContext = context;
    final auth = rootContext.read<AuthProvider>();
    final formKey = GlobalKey<FormState>();
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    final success = await showModalBottomSheet<bool>(
      context: rootContext,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(modalContext).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentController,
                    obscureText: obscureCurrent,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrent
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setModalState(
                          () => obscureCurrent = !obscureCurrent,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Nhập mật khẩu hiện tại'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu mới',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () =>
                            setModalState(() => obscureNew = !obscureNew),
                      ),
                    ),
                    validator: (value) => value != null && value.length >= 6
                        ? null
                        : 'Mật khẩu tối thiểu 6 ký tự',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận mật khẩu mới',
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setModalState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                      ),
                    ),
                    validator: (value) => value == newController.text
                        ? null
                        : 'Mật khẩu xác nhận không trùng khớp',
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) {
                        return;
                      }
                      FocusScope.of(modalContext).unfocus();
                      final ok = await auth.changePassword(
                        currentPassword: currentController.text,
                        newPassword: newController.text,
                      );
                      if (!mounted) {
                        return;
                      }
                      if (ok) {
                        Navigator.of(modalContext).pop(true);
                      } else if (auth.error != null) {
                        ScaffoldMessenger.of(
                          rootContext,
                        ).showSnackBar(SnackBar(content: Text(auth.error!)));
                      }
                    },
                    child: const Text('Đổi mật khẩu'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );

    _disposeTextControllers([
      currentController,
      newController,
      confirmController,
    ]);

    if (success == true && mounted) {
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công')));
    }
  }
}

class _ExamTab extends StatelessWidget {
  final TextEditingController searchController;
  final int? selectedChuDeId;
  final ValueChanged<int?> onTopicSelected;
  final ValueChanged<DeThi> onOpenExam;

  const _ExamTab({
    required this.searchController,
    required this.selectedChuDeId,
    required this.onTopicSelected,
    required this.onOpenExam,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer2<DeThiProvider, ChuDeProvider>(
      builder: (context, deThiProvider, chuDeProvider, _) {
        final keyword = searchController.text.trim().toLowerCase();
        final selected = selectedChuDeId;
        final items = deThiProvider.openDeThis.where((deThi) {
          final matchesKeyword =
              keyword.isEmpty ||
              deThi.tenDeThi.toLowerCase().contains(keyword) ||
              (deThi.chuDe?.tenChuDe.toLowerCase().contains(keyword) ?? false);
          final matchesTopic = selected == null || deThi.chuDeId == selected;
          return matchesKeyword && matchesTopic;
        }).toList();

        String topicNameFor(DeThi deThi) {
          final nested = deThi.chuDe?.tenChuDe;
          if (nested != null && nested.isNotEmpty) {
            return nested;
          }
          for (final topic in chuDeProvider.chuDes) {
            if (topic.id == deThi.chuDeId) {
              return topic.tenChuDe;
            }
          }
          return 'Chưa cập nhật';
        }

        return RefreshIndicator(
          onRefresh: () => deThiProvider.fetchOpenDeThis(),
          child: ListView(
            padding: EdgeInsets.all(16.w),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              // Search Bar
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm đề thi...',
                  hintStyle: TextStyle(fontSize: 14.sp),
                  prefixIcon: Icon(Icons.search, size: 20.sp),
                  suffixIcon: keyword.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20.sp),
                          onPressed: () => searchController.clear(),
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),

              UIHelpers.verticalSpaceMedium(),

              // Topic Filter Row
              Row(
                children: [
                  Icon(
                    Icons.filter_list,
                    size: 20.sp,
                    color: theme.colorScheme.primary,
                  ),
                  UIHelpers.horizontalSpaceSmall(),
                  Text(
                    'Chủ đề:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  UIHelpers.horizontalSpaceSmall(),
                  Expanded(
                    child: Container(
                      height: 40.h,
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int?>(
                          value: selected,
                          isExpanded: true,
                          icon: Icon(Icons.arrow_drop_down, size: 20.sp),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          items: [
                            DropdownMenuItem<int?>(
                              value: null,
                              child: Text(
                                'Tất cả chủ đề',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            ),
                            for (final chuDe in chuDeProvider.chuDes)
                              DropdownMenuItem<int?>(
                                value: chuDe.id,
                                child: Text(
                                  chuDe.tenChuDe,
                                  style: TextStyle(fontSize: 14.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) => onTopicSelected(value),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              UIHelpers.verticalSpaceMedium(),

              // Result Count
              if (!deThiProvider.loadingOpen) ...[
                Row(
                  children: [
                    Text(
                      'Tìm thấy ${items.length} đề thi',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.textTheme.bodySmall?.color,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    if (selected != null || keyword.isNotEmpty) ...[
                      UIHelpers.horizontalSpaceSmall(),
                      TextButton.icon(
                        onPressed: () {
                          searchController.clear();
                          onTopicSelected(null);
                        },
                        icon: Icon(Icons.clear_all, size: 16.sp),
                        label: Text(
                          'Xóa bộ lọc',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                UIHelpers.verticalSpaceSmall(),
              ],

              // Loading State
              if (deThiProvider.loadingOpen)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.h),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 3.w),
                        UIHelpers.verticalSpaceSmall(),
                        Text(
                          'Đang tải đề thi...',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                )
              // Empty State
              else if (items.isEmpty)
                EmptyStateWidget(
                  icon: Icons.quiz_outlined,
                  message: keyword.isNotEmpty || selected != null
                      ? 'Không tìm thấy đề thi phù hợp'
                      : 'Chưa có đề thi nào',
                )
              // Exam List
              else
                ...items.map(
                  (deThi) => Card(
                    margin: EdgeInsets.only(bottom: 12.h),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: InkWell(
                      onTap: () => onOpenExam(deThi),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          children: [
                            // Icon
                            Container(
                              width: 56.w,
                              height: 56.h,
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
                                Icons.description_outlined,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                            ),

                            UIHelpers.horizontalSpaceMedium(),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deThi.tenDeThi,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15.sp,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  UIHelpers.verticalSpaceSmall(),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 14.sp,
                                        color: theme.colorScheme.primary,
                                      ),
                                      SizedBox(width: 4.w),
                                      Expanded(
                                        child: Text(
                                          topicNameFor(deThi),
                                          style: TextStyle(
                                            fontSize: 13.sp,
                                            color: theme.colorScheme.primary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 14.sp,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '${deThi.thoiGianThi} phút',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Icon(
                                        Icons.quiz_outlined,
                                        size: 14.sp,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '${deThi.soCauHoi} câu',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Arrow Icon
                            Icon(
                              Icons.chevron_right,
                              size: 24.sp,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final ValueChanged<KetQuaThiSummary> onViewDetail;
  final String? restrictToUserId;

  const _HistoryTab({required this.onViewDetail, this.restrictToUserId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<KetQuaThiProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () => provider.fetchKetQuaThiList(
            page: provider.ketQuaThiList?.page ?? 1,
            onlyUserId: restrictToUserId,
          ),
          child: provider.isLoading && provider.ketQuaThiList == null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 48.h),
                  children: [
                    Center(
                      child: Column(
                        children: [
                          CircularProgressIndicator(strokeWidth: 3.w),
                          UIHelpers.verticalSpaceSmall(),
                          Text(
                            'Đang tải lịch sử...',
                            style: TextStyle(fontSize: 13.sp),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : () {
                  final rawItems = provider.ketQuaThiList?.items;
                  List<KetQuaThiSummary>? items = rawItems;
                  if (restrictToUserId != null && rawItems != null) {
                    items = rawItems
                        .where(
                          (e) =>
                              (e.taiKhoan?.id ?? e.taiKhoanId) == null ||
                              (e.taiKhoan?.id ?? e.taiKhoanId) ==
                                  restrictToUserId,
                        )
                        .toList(growable: false);
                  }
                  final list = items;
                  if (list == null || list.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        EmptyStateWidget(
                          icon: Icons.history_outlined,
                          message:
                              'Chưa có lịch sử làm bài.\nHãy bắt đầu làm bài thi đầu tiên!',
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.all(16.w),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      final summary = list[index];
                      final statusColor = summary.isCompleted
                          ? Colors.green.shade600
                          : theme.colorScheme.secondary;
                      final dateString = UIHelpers.formatDateVN(
                        summary.ngayThi,
                      );
                      final statusText = summary.isCompleted
                          ? 'Hoàn thành'
                          : 'Đang làm';

                      return Dismissible(
                        key: ValueKey('kq-${summary.id}'),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          // Only allow deletion when list is restricted to current user
                          if (restrictToUserId == null ||
                              (summary.taiKhoan?.id ?? summary.taiKhoanId) !=
                                  restrictToUserId) {
                            return false;
                          }

                          final confirm = await UIHelpers.showConfirmDialog(
                            context,
                            title: 'Xóa lịch sử',
                            message:
                                'Bạn có chắc muốn xóa kết quả bài thi này?\nHành động này không thể hoàn tác.',
                            confirmText: 'Xóa',
                            cancelText: 'Hủy',
                            isDangerous: true,
                          );

                          if (confirm != true) return false;

                          final ok = await context
                              .read<KetQuaThiProvider>()
                              .deleteKetQuaThi(summary.id);
                          if (ok) {
                            UIHelpers.showSuccessSnackBar(
                              context,
                              'Đã xóa lịch sử thi thành công',
                            );
                          } else {
                            final msg =
                                context.read<KetQuaThiProvider>().error ??
                                'Không thể xóa lịch sử thi. Vui lòng thử lại.';
                            UIHelpers.showErrorSnackBar(context, msg);
                          }
                          return ok;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 28.sp,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Xóa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: InkWell(
                            onTap: () => onViewDetail(summary),
                            borderRadius: BorderRadius.circular(12.r),
                            child: Padding(
                              padding: EdgeInsets.all(12.w),
                              child: Row(
                                children: [
                                  // Status Icon
                                  Container(
                                    width: 56.w,
                                    height: 56.h,
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    child: Icon(
                                      summary.isCompleted
                                          ? Icons.check_circle_outline
                                          : Icons.pending_outlined,
                                      color: statusColor,
                                      size: 28.sp,
                                    ),
                                  ),

                                  UIHelpers.horizontalSpaceMedium(),

                                  // Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          summary.deThi?.tenDeThi ??
                                              'Đề thi #${summary.id}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15.sp,
                                              ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        UIHelpers.verticalSpaceSmall(),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 14.sp,
                                              color: theme
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color,
                                            ),
                                            SizedBox(width: 4.w),
                                            Expanded(
                                              child: Text(
                                                dateString,
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: theme
                                                      .textTheme
                                                      .bodySmall
                                                      ?.color,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (summary.diem != null) ...[
                                          SizedBox(height: 4.h),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.stars_outlined,
                                                size: 14.sp,
                                                color: Colors.amber.shade700,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                'Điểm: ${summary.diem!.toStringAsFixed(1)}',
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.amber.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Status Badge
                                  Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 10.w,
                                          vertical: 6.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20.r,
                                          ),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Icon(
                                        Icons.chevron_right,
                                        size: 20.sp,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }(),
        );
      },
    );
  }
}

// Màn cũ _ResultDetailSheet đã thay bằng ResultReviewScreen

class _ContactFormResult {
  final String title;
  final String content;

  const _ContactFormResult({required this.title, required this.content});
}

class _ContactTab extends StatelessWidget {
  final Future<void> Function(BuildContext) onCreate;

  const _ContactTab({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LienHeProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () => provider.fetchMine(),
          child: () {
            if (provider.isLoading && provider.myLienHe == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(vertical: 48.h),
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(strokeWidth: 3.w),
                        UIHelpers.verticalSpaceSmall(),
                        Text(
                          'Đang tải góp ý...',
                          style: TextStyle(fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (provider.error != null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  ErrorStateWidget(
                    message: provider.error!,
                    onRetry: () => provider.fetchMine(),
                  ),
                ],
              );
            }

            final items = provider.myLienHe ?? const <LienHe>[];
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  EmptyStateWidget(
                    icon: Icons.feedback_outlined,
                    message:
                        'Chưa có góp ý nào.\nHãy gửi góp ý đầu tiên của bạn!',
                    actionText: 'Gửi góp ý',
                    onActionPressed: () => onCreate(context),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(16.w),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, index) {
                final lienHe = items[index];
                final date = UIHelpers.formatDateVN(lienHe.ngayGui);

                return Dismissible(
                  key: ValueKey(lienHe.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    final confirm = await UIHelpers.showConfirmDialog(
                      context,
                      title: 'Xóa góp ý',
                      message: 'Bạn có chắc muốn xóa góp ý này?',
                      confirmText: 'Xóa',
                      cancelText: 'Hủy',
                      isDangerous: true,
                    );

                    if (confirm != true) return false;

                    final success = await provider.deleteLienHe(lienHe.id);
                    if (success) {
                      UIHelpers.showSuccessSnackBar(
                        context,
                        'Đã xóa góp ý thành công',
                      );
                    } else {
                      final message =
                          provider.error ??
                          'Không thể xóa góp ý. Vui lòng thử lại.';
                      UIHelpers.showErrorSnackBar(context, message);
                    }
                    return success;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28.sp,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Xóa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: InkWell(
                      onTap: () => _showEditContact(context, lienHe),
                      borderRadius: BorderRadius.circular(12.r),
                      child: Padding(
                        padding: EdgeInsets.all(12.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Icon
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
                                Icons.message_outlined,
                                color: Colors.white,
                                size: 24.sp,
                              ),
                            ),

                            UIHelpers.horizontalSpaceMedium(),

                            // Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lienHe.tieuDe,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15.sp,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  UIHelpers.verticalSpaceSmall(),
                                  Text(
                                    lienHe.noiDung,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: theme.textTheme.bodyMedium?.color,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 6.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today_outlined,
                                        size: 12.sp,
                                        color: theme.textTheme.bodySmall?.color,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        date,
                                        style: TextStyle(
                                          fontSize: 11.sp,
                                          color:
                                              theme.textTheme.bodySmall?.color,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Edit Icon
                            Icon(
                              Icons.edit_outlined,
                              size: 20.sp,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }(),
        );
      },
    );
  }

  Future<void> _showEditContact(BuildContext rootContext, LienHe lienHe) async {
    final theme = Theme.of(rootContext);
    final provider = rootContext.read<LienHeProvider>();
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: lienHe.tieuDe);
    final contentController = TextEditingController(text: lienHe.noiDung);

    final result = await showModalBottomSheet<_ContactFormResult?>(
      context: rootContext,
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
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
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
                          'Chỉnh sửa góp ý',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18.sp,
                          ),
                        ),
                      ],
                    ),
                    UIHelpers.verticalSpaceMedium(),

                    // Title Field
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Tiêu đề',
                        hintText: 'Nhập tiêu đề góp ý',
                        prefixIcon: Icon(Icons.title, size: 20.sp),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập tiêu đề'
                          : null,
                    ),
                    UIHelpers.verticalSpaceMedium(),

                    // Content Field
                    TextFormField(
                      controller: contentController,
                      decoration: InputDecoration(
                        labelText: 'Nội dung',
                        hintText: 'Nhập nội dung góp ý',
                        prefixIcon: Icon(
                          Icons.description_outlined,
                          size: 20.sp,
                        ),
                        alignLabelWithHint: true,
                      ),
                      minLines: 4,
                      maxLines: 8,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập nội dung'
                          : null,
                    ),
                    UIHelpers.verticalSpaceLarge(),

                    // Save Button
                    FilledButton.icon(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        FocusScope.of(sheetContext).unfocus();
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop(
                          _ContactFormResult(
                            title: titleController.text.trim(),
                            content: contentController.text.trim(),
                          ),
                        );
                      },
                      icon: Icon(Icons.check, size: 20.sp),
                      label: const Text('Lưu thay đổi'),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                    ),
                    UIHelpers.verticalSpaceSmall(),

                    // Cancel Button
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

    if (result == null) return;

    UIHelpers.showLoadingDialog(rootContext);
    await provider.updateLienHe(
      id: lienHe.id,
      tieuDe: result.title,
      noiDung: result.content,
    );

    if (rootContext.mounted) Navigator.pop(rootContext); // Close loading

    if (provider.error != null && rootContext.mounted) {
      UIHelpers.showErrorSnackBar(rootContext, provider.error!);
      return;
    }

    if (rootContext.mounted) {
      UIHelpers.showSuccessSnackBar(rootContext, 'Đã cập nhật góp ý');
    }
  }
}

class _ProfileTab extends StatelessWidget {
  final Future<void> Function(BuildContext) onEditProfile;
  final Future<void> Function(BuildContext) onChangePassword;
  final Future<void> Function(BuildContext) onLogout;

  const _ProfileTab({
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return const Center(child: Text('Không tìm thấy thông tin người dùng'));
    }

    final initial = user.fullName.isNotEmpty
        ? user.fullName[0].toUpperCase()
        : user.userName[0].toUpperCase();

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Profile Header Card
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              children: [
                // Avatar with gradient border
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40.r,
                    backgroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 32.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                UIHelpers.verticalSpaceMedium(),

                // Name
                Text(
                  user.fullName.isNotEmpty ? user.fullName : user.userName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4.h),

                // Email
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14.sp,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                    SizedBox(width: 4.w),
                    Flexible(
                      child: Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        UIHelpers.verticalSpaceLarge(),

        // Account Section
        UIHelpers.sectionHeader(context, 'Tài khoản'),
        UIHelpers.verticalSpaceSmall(),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 20.sp,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text(
                  'Chỉnh sửa thông tin',
                  style: TextStyle(fontSize: 14.sp),
                ),
                trailing: Icon(Icons.chevron_right, size: 20.sp),
                onTap: () => onEditProfile(context),
              ),
              Divider(height: 1.h, indent: 56.w),
              ListTile(
                leading: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.lock_reset_outlined,
                    size: 20.sp,
                    color: theme.colorScheme.secondary,
                  ),
                ),
                title: Text('Đổi mật khẩu', style: TextStyle(fontSize: 14.sp)),
                trailing: Icon(Icons.chevron_right, size: 20.sp),
                onTap: () => onChangePassword(context),
              ),
              Divider(height: 1.h, indent: 56.w),
              _TwoFaTile(),
            ],
          ),
        ),

        UIHelpers.verticalSpaceLarge(),

        // Settings Section
        UIHelpers.sectionHeader(context, 'Cài đặt'),
        UIHelpers.verticalSpaceSmall(),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Column(
            children: [
              SwitchListTile(
                secondary: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.dark_mode_outlined,
                    size: 20.sp,
                    color: theme.colorScheme.primary,
                  ),
                ),
                title: Text('Chế độ tối', style: TextStyle(fontSize: 14.sp)),
                value: theme.brightness == Brightness.dark,
                onChanged: (_) {
                  UIHelpers.showInfoSnackBar(
                    context,
                    'Tính năng sẽ sớm được hỗ trợ',
                  );
                },
              ),
              Divider(height: 1.h, indent: 56.w),
              SwitchListTile(
                secondary: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    size: 20.sp,
                    color: Colors.orange,
                  ),
                ),
                title: Text(
                  'Thông báo hoạt động',
                  style: TextStyle(fontSize: 14.sp),
                ),
                value: true,
                onChanged: (_) {
                  UIHelpers.showInfoSnackBar(
                    context,
                    'Tính năng thông báo đang được phát triển',
                  );
                },
              ),
              Divider(height: 1.h, indent: 56.w),
              ListTile(
                leading: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.bar_chart_outlined,
                    size: 20.sp,
                    color: Colors.purple,
                  ),
                ),
                title: Text(
                  'Thống kê kết quả',
                  style: TextStyle(fontSize: 14.sp),
                ),
                trailing: Icon(Icons.chevron_right, size: 20.sp),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                  );
                },
              ),
              Divider(height: 1.h, indent: 56.w),
              ListTile(
                leading: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.logout,
                    size: 20.sp,
                    color: theme.colorScheme.error,
                  ),
                ),
                title: Text(
                  'Đăng xuất',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: theme.colorScheme.error,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  size: 20.sp,
                  color: theme.colorScheme.error,
                ),
                onTap: () => onLogout(context),
              ),
            ],
          ),
        ),

        UIHelpers.verticalSpaceLarge(),
      ],
    );
  }
}

// _ResultDetailSheet: màn cũ đã được thay bằng ResultReviewScreen

class _EditProfileSheet extends StatefulWidget {
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? birthday;
  final String? gender;

  const _EditProfileSheet({
    required this.fullName,
    required this.email,
    this.phone,
    this.birthday,
    this.gender,
  });

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _genderController;
  DateTime? _birthday;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.fullName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone ?? '');
    _genderController = TextEditingController(text: widget.gender ?? '');
    _birthday = widget.birthday;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Họ và tên'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập họ tên'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Email không hợp lệ'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _birthday == null
                            ? 'Ngày sinh: chưa cập nhật'
                            : 'Ngày sinh: ${UIHelpers.formatDateOnlyVN(_birthday!)}',
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _birthday ?? DateTime.now(),
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _birthday = picked);
                        }
                      },
                      child: const Text('Chọn ngày'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _genderController,
                  decoration: const InputDecoration(labelText: 'Giới tính'),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    FocusScope.of(context).unfocus();
                    final auth = context.read<AuthProvider>();
                    await auth.updateProfile(
                      fullName: _fullNameController.text.trim(),
                      email: _emailController.text.trim(),
                      soDienThoai: _phoneController.text.trim().isEmpty
                          ? null
                          : _phoneController.text.trim(),
                      ngaySinh: _birthday,
                      gioiTinh: _genderController.text.trim().isEmpty
                          ? null
                          : _genderController.text.trim(),
                    );
                    if (!mounted) return;
                    if (auth.error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(auth.error!)));
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Lưu thay đổi'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TwoFaTile extends StatefulWidget {
  @override
  State<_TwoFaTile> createState() => _TwoFaTileState();
}

class _TwoFaTileState extends State<_TwoFaTile> {
  bool? _enabled;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<AuthProvider>();
      final status = await service.getTwoFaStatus();
      if (mounted) setState(() => _enabled = status);
    } catch (_) {
      if (mounted) setState(() => _enabled = false);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = _enabled == true
        ? 'Đang bật - yêu cầu mã khi đăng nhập'
        : 'Đang tắt - đăng nhập bình thường';
    return ListTile(
      leading: const Icon(Icons.verified_user_outlined),
      title: const Text('Xác thực 2 bước (2FA)'),
      subtitle: Text(subtitle),
      trailing: _loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Switch(
              value: _enabled ?? false,
              onChanged: (value) => _onToggle(context, value),
            ),
      onTap: () => _onToggle(context, !(_enabled ?? false)),
    );
  }

  Future<void> _onToggle(BuildContext context, bool value) async {
    final authProvider = context.read<AuthProvider>();
    if (value) {
      // Enable: fetch setup info and prompt user to verify code
      setState(() => _loading = true);
      try {
        final setup = await authProvider.setupTwoFa();
        if (!mounted) return;
        await _showEnableDialog(
          context,
          setup.sharedKey,
          setup.authenticatorUri,
        );
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể bật 2FA: $e')));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      // Disable directly
      setState(() => _loading = true);
      try {
        await authProvider.disableTwoFa();
        await _load();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể tắt 2FA: $e')));
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  Future<void> _showEnableDialog(
    BuildContext context,
    String sharedKey,
    String authenticatorUri,
  ) async {
    final codeController = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Bật xác thực 2 bước'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('1) Mở Google Authenticator và quét mã:'),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: qr.QrImageView(
                      data: authenticatorUri,
                      version: qr.QrVersions.auto,
                      gapless: true,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  authenticatorUri,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text('2) Hoặc nhập khóa thủ công:'),
                SelectableText(sharedKey),
                const SizedBox(height: 8),
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Nhập mã 6 số để xác nhận',
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                final code = codeController.text.trim();
                if (code.length != 6) return;
                try {
                  await dialogContext.read<AuthProvider>().enableTwoFa(
                    code: code,
                  );
                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã bật xác thực 2 bước')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Mã không hợp lệ: $e')),
                  );
                }
              },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );
    // Do not dispose codeController here to avoid a race during dialog teardown
    // and rebuilds triggered by provider updates. It's short-lived and will be
    // GC'd after dialog is closed.
  }
}
