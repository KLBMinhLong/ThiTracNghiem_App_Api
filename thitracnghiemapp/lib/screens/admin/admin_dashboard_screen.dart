import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../models/cau_hoi.dart';
import '../../models/chu_de.dart';
import '../../models/de_thi.dart';
import '../../models/lien_he.dart';
import '../../models/user.dart';
import '../../providers/cau_hoi_provider.dart';
import '../../providers/chu_de_provider.dart';
import '../../providers/de_thi_provider.dart';
import '../../providers/lien_he_provider.dart';
import '../../providers/users_provider.dart';
import '../../utils/ui_helpers.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _userKeywordController = TextEditingController();
  final TextEditingController _topicSearchController = TextEditingController();
  final TextEditingController _examKeywordController = TextEditingController();
  int _selectedIndex = 0;
  int _userPage = 1;
  int _examPage = 1;
  bool _isImportingQuestions = false;
  bool _showQuestionFilters = false;
  bool _showExamFilters = false;
  int? _selectedTopicForImport;
  int? _examTopicFilterId;
  String? _examStatusFilter; // 'Mo', 'Dong', or null for all

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _userKeywordController.dispose();
    _topicSearchController.dispose();
    _examKeywordController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      context.read<UsersProvider>().fetchUsers(page: _userPage),
      context.read<ChuDeProvider>().fetchChuDes(),
      context.read<CauHoiProvider>().refreshCauHois(),
      context.read<DeThiProvider>().fetchAdminDeThis(page: _examPage),
      context.read<LienHeProvider>().fetchAll(),
    ]);
  }

  Future<void> _importQuestions() async {
    try {
      final topicId = _selectedTopicForImport;
      if (topicId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn chủ đề trước khi import.'),
          ),
        );
        return;
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final picked = result.files.first;
      final path = picked.path;
      if (path == null) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết bị không hỗ trợ import file Excel .xlsx.'),
          ),
        );
        return;
      }

      setState(() => _isImportingQuestions = true);

      final provider = context.read<CauHoiProvider>();
      final successMessage = await provider.importCauHois(
        File(path),
        topicId: topicId,
      );

      if (!mounted) {
        return;
      }

      setState(() => _isImportingQuestions = false);

      final messenger = ScaffoldMessenger.of(context);
      if (successMessage != null) {
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      } else {
        final errorMessage = provider.error ?? 'Import câu hỏi thất bại.';
        messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isImportingQuestions = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể đọc file Excel: $error')),
      );
    }
  }

  // Removed controller disposal helper to avoid races during dialog teardown.

  @override
  Widget build(BuildContext context) {
    final sections = [
      _AdminSection(title: 'Người dùng', icon: Icons.people_alt_outlined),
      _AdminSection(title: 'Chủ đề', icon: Icons.category_outlined),
      _AdminSection(title: 'Câu hỏi', icon: Icons.quiz_outlined),
      _AdminSection(title: 'Đề thi', icon: Icons.assignment_outlined),
      _AdminSection(title: 'Liên hệ', icon: Icons.mail_outline),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth > 900;
        final body = _buildSectionBody(_selectedIndex);
        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.grey.shade800,
            title: Row(
              children: [
                Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Bảng điều khiển quản trị',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          body: useRail
              ? Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) =>
                            setState(() => _selectedIndex = index),
                        labelType: NavigationRailLabelType.all,
                        backgroundColor: Colors.white,
                        selectedIconTheme: IconThemeData(
                          color: Theme.of(context).colorScheme.primary,
                          size: 28.sp,
                        ),
                        unselectedIconTheme: IconThemeData(
                          color: Colors.grey.shade600,
                          size: 24.sp,
                        ),
                        selectedLabelTextStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        unselectedLabelTextStyle: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey.shade600,
                        ),
                        destinations: [
                          for (final section in sections)
                            NavigationRailDestination(
                              icon: Icon(section.icon),
                              label: Text(section.title),
                            ),
                        ],
                      ),
                    ),
                    Expanded(child: body),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: body),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: NavigationBar(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (index) =>
                            setState(() => _selectedIndex = index),
                        backgroundColor: Colors.white,
                        indicatorColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysShow,
                        height: 64.h,
                        destinations: [
                          for (final section in sections)
                            NavigationDestination(
                              icon: Icon(section.icon, size: 22.sp),
                              selectedIcon: Icon(
                                section.icon,
                                size: 24.sp,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              label: section.title,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildSectionBody(int index) {
    switch (index) {
      case 0:
        return _buildUsersSection();
      case 1:
        return _buildTopicsSection();
      case 2:
        return _buildQuestionsSection();
      case 3:
        return _buildExamsSection();
      case 4:
        return _buildContactsSection();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildUsersSection() {
    return Consumer<UsersProvider>(
      builder: (context, provider, _) {
        final response = provider.users;
        return Container(
          color: Colors.grey.shade50,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Header với search và actions
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search field (full width)
                      Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _userKeywordController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20.sp,
                              color: Colors.grey.shade600,
                            ),
                            hintText: 'Tìm kiếm theo tên hoặc email...',
                            hintStyle: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                          ),
                          style: TextStyle(fontSize: 13.sp),
                          onSubmitted: (_) => _searchUsers(),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Action buttons row
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              onTap: () => _showCreateUserDialog(),
                              icon: Icons.person_add_alt_1,
                              label: 'Thêm tài khoản',
                              isPrimary: true,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: _buildActionButton(
                              onTap: _searchUsers,
                              icon: Icons.refresh,
                              label: 'Tải lại',
                              isPrimary: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Content
                if (provider.isLoading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (response == null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80.w,
                            height: 80.w,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Icon(
                              Icons.people_outline,
                              size: 40.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Text(
                            'Không có dữ liệu người dùng',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _searchUsers,
                      child: ListView.separated(
                        itemCount: response.items.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final user = response.items[index];
                          final isAdmin = user.roles.any(
                            (role) => role.toLowerCase() == 'admin',
                          );
                          return Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: InkWell(
                              onTap: () => _showUserDialog(user),
                              borderRadius: BorderRadius.circular(12.r),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 48.w,
                                      height: 48.w,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isAdmin
                                              ? [
                                                  Colors.purple.shade400,
                                                  Colors.purple.shade600,
                                                ]
                                              : [
                                                  Colors.blue.shade400,
                                                  Colors.blue.shade600,
                                                ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          user.userName
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16.w),

                                    // Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  user.fullName.isNotEmpty
                                                      ? user.fullName
                                                      : user.userName,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isAdmin) ...[
                                                SizedBox(width: 8.w),
                                                _buildBadge(
                                                  'Admin',
                                                  Colors.purple,
                                                ),
                                              ],
                                              if (user.isLocked) ...[
                                                SizedBox(width: 8.w),
                                                _buildBadge('Khoá', Colors.red),
                                              ],
                                            ],
                                          ),
                                          if (user.email.isNotEmpty) ...[
                                            SizedBox(height: 4.h),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.email_outlined,
                                                  size: 12.sp,
                                                  color: Colors.grey.shade600,
                                                ),
                                                SizedBox(width: 6.w),
                                                Flexible(
                                                  child: Text(
                                                    user.email,
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // Actions
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        size: 20.sp,
                                        color: Colors.grey.shade600,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      itemBuilder: (context) => [
                                        _buildPopupMenuItem(
                                          'edit',
                                          Icons.edit_outlined,
                                          'Chỉnh sửa',
                                          Colors.blue.shade700,
                                        ),
                                        _buildPopupMenuItem(
                                          'delete',
                                          Icons.delete_outline,
                                          'Xoá',
                                          Colors.red.shade700,
                                        ),
                                      ],
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showUserDialog(user);
                                        } else if (value == 'delete') {
                                          _deleteUser(user);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Pagination
                if (response != null)
                  _buildPagination(
                    response.isLastPage,
                    _userPage,
                    () {
                      setState(() => _userPage--);
                      provider.fetchUsers(
                        keyword: _userKeywordController.text.trim().isEmpty
                            ? null
                            : _userKeywordController.text.trim(),
                        page: _userPage,
                      );
                    },
                    () {
                      setState(() => _userPage++);
                      provider.fetchUsers(
                        keyword: _userKeywordController.text.trim().isEmpty
                            ? null
                            : _userKeywordController.text.trim(),
                        page: _userPage,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required IconData icon,
    required String label,
    required bool isPrimary,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: 48.h),
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              )
            : null,
        color: isPrimary ? null : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: isPrimary
            ? null
            : Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18.sp,
                  color: isPrimary
                      ? Colors.white
                      : Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8.w),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isPrimary
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String label, MaterialColor colorSwatch) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        gradient: label == 'Khoá'
            ? null
            : LinearGradient(colors: [colorSwatch[400]!, colorSwatch[600]!]),
        color: label == 'Khoá' ? colorSwatch[50] : null,
        borderRadius: BorderRadius.circular(6.r),
        border: label == 'Khoá' ? Border.all(color: colorSwatch[300]!) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
          color: label == 'Khoá' ? colorSwatch[700] : Colors.white,
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildPopupMenuItem(
    String value,
    IconData icon,
    String label,
    Color color,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: color),
          SizedBox(width: 12.w),
          Text(label, style: TextStyle(fontSize: 13.sp)),
        ],
      ),
    );
  }

  Widget _buildPagination(
    bool isLastPage,
    int currentPage,
    VoidCallback onPrevious,
    VoidCallback onNext,
  ) {
    return Container(
      margin: EdgeInsets.only(top: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPaginationButton(
            icon: Icons.chevron_left,
            enabled: currentPage > 1,
            onPressed: onPrevious,
          ),
          SizedBox(width: 16.w),
          Text(
            'Trang $currentPage',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(width: 16.w),
          _buildPaginationButton(
            icon: Icons.chevron_right,
            enabled: !isLastPage,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 36.w,
      height: 36.w,
      decoration: BoxDecoration(
        color: enabled
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(
          icon,
          size: 20.sp,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400,
        ),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _showCreateUserDialog() async {
    final rootContext = context;
    final usersProvider = rootContext.read<UsersProvider>();
    final formKey = GlobalKey<FormState>();
    final userNameController = TextEditingController();
    final emailController = TextEditingController();
    final fullNameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isAdmin = false;

    final confirm = await showDialog<bool>(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: const Text('Thêm người dùng'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: userNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                    ),
                    validator: (v) => v == null || v.trim().length < 3
                        ? 'Nhập tên đăng nhập (>= 3 ký tự)'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (tuỳ chọn)',
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên (tuỳ chọn)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                    validator: (v) => v == null || v.trim().length < 6
                        ? 'Mật khẩu tối thiểu 6 ký tự'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isAdmin,
                    onChanged: (val) => setState(() => isAdmin = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Cấp quyền quản trị (Admin)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                FocusScope.of(dialogContext).unfocus();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Tạo'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    final created = await usersProvider.createUser(
      userName: userNameController.text.trim(),
      email: emailController.text.trim().isEmpty
          ? null
          : emailController.text.trim(),
      fullName: fullNameController.text.trim().isEmpty
          ? null
          : fullNameController.text.trim(),
      password: passwordController.text,
      roles: isAdmin ? ['Admin'] : ['User'],
    );
    if (!mounted) return;
    if (created != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã tạo người dùng')));
      await _searchUsers();
    } else {
      final message = usersProvider.error ?? 'Không thể tạo người dùng.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _deleteUser(User user) async {
    final usersProvider = context.read<UsersProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xoá người dùng'),
        content: Text('Bạn có chắc muốn xoá tài khoản ${user.userName}?'),
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

    final ok = await usersProvider.deleteUser(user.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xoá người dùng')));
      await _searchUsers();
    } else {
      final message = usersProvider.error ?? 'Không thể xoá người dùng.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Widget _buildTopicsSection() {
    return Consumer<ChuDeProvider>(
      builder: (context, provider, _) {
        final topics = provider.chuDes;
        final keyword = _topicSearchController.text.trim().toLowerCase();
        final filteredTopics = keyword.isEmpty
            ? topics
            : topics
                  .where(
                    (t) =>
                        t.tenChuDe.toLowerCase().contains(keyword) ||
                        (t.moTa ?? '').toLowerCase().contains(keyword),
                  )
                  .toList(growable: false);
        return Container(
          color: Colors.grey.shade50,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header với search
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            controller: _topicSearchController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(
                                Icons.search,
                                size: 20.sp,
                                color: Colors.grey.shade600,
                              ),
                              hintText: 'Tìm kiếm chủ đề theo tên hoặc mô tả',
                              hintStyle: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                            ),
                            style: TextStyle(fontSize: 13.sp),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      if (_topicSearchController.text.isNotEmpty) ...[
                        SizedBox(width: 12.w),
                        Container(
                          width: 48.w,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: IconButton(
                            tooltip: 'Xoá tìm kiếm',
                            onPressed: () {
                              _topicSearchController.clear();
                              setState(() {});
                            },
                            icon: Icon(
                              Icons.clear,
                              size: 20.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                      SizedBox(width: 12.w),
                      _buildActionButton(
                        onTap: () => _showTopicDialog(),
                        icon: Icons.add,
                        label: 'Thêm chủ đề',
                        isPrimary: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Content
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : filteredTopics.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80.w,
                                height: 80.w,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Icon(
                                  Icons.category_outlined,
                                  size: 40.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                keyword.isEmpty
                                    ? 'Chưa có chủ đề nào'
                                    : 'Không tìm thấy chủ đề',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filteredTopics.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final topic = filteredTopics[index];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: InkWell(
                                onTap: () => _showTopicDialog(topic: topic),
                                borderRadius: BorderRadius.circular(12.r),
                                child: Padding(
                                  padding: EdgeInsets.all(16.w),
                                  child: Row(
                                    children: [
                                      // Icon
                                      Container(
                                        width: 48.w,
                                        height: 48.w,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.folder_outlined,
                                          size: 24.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 16.w),

                                      // Info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              topic.tenChuDe,
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (topic.moTa != null &&
                                                topic.moTa!.isNotEmpty) ...[
                                              SizedBox(height: 4.h),
                                              Text(
                                                topic.moTa!,
                                                style: TextStyle(
                                                  fontSize: 12.sp,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // Actions
                                      PopupMenuButton<String>(
                                        icon: Icon(
                                          Icons.more_vert,
                                          size: 20.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12.r,
                                          ),
                                        ),
                                        itemBuilder: (context) => [
                                          _buildPopupMenuItem(
                                            'edit',
                                            Icons.edit_outlined,
                                            'Chỉnh sửa',
                                            Colors.blue.shade700,
                                          ),
                                          _buildPopupMenuItem(
                                            'delete',
                                            Icons.delete_outline,
                                            'Xoá',
                                            Colors.red.shade700,
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showTopicDialog(topic: topic);
                                          } else if (value == 'delete') {
                                            _deleteTopic(topic.id);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionsSection() {
    return Consumer2<CauHoiProvider, ChuDeProvider>(
      builder: (context, questionProvider, topicProvider, _) {
        final questions = questionProvider.cauHois;
        final topics = topicProvider.chuDes;

        if (_selectedTopicForImport == null && topics.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _selectedTopicForImport = topics.first.id);
          });
        } else if (_selectedTopicForImport != null &&
            topics.every((topic) => topic.id != _selectedTopicForImport)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(
              () => _selectedTopicForImport = topics.isNotEmpty
                  ? topics.first.id
                  : null,
            );
          });
        }
        final selectedFilter = questionProvider.selectedTopicId;
        final filterValue = topics.any((topic) => topic.id == selectedFilter)
            ? selectedFilter
            : null;
        final errorText = questionProvider.error;
        final isInitialLoading =
            questionProvider.isLoading && questions.isEmpty;

        return Container(
          color: Colors.grey.shade50,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Filters và Actions
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Main action row (always visible)
                      Row(
                        children: [
                          // Filter toggle button
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(
                                () => _showQuestionFilters =
                                    !_showQuestionFilters,
                              );
                            },
                            icon: Icon(
                              _showQuestionFilters
                                  ? Icons.filter_alt
                                  : Icons.filter_alt_outlined,
                              size: 18.sp,
                            ),
                            label: Text(
                              'Lọc',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _buildActionButton(
                            onTap: () => _showQuestionDialog(),
                            icon: Icons.add,
                            label: 'Thêm câu hỏi',
                            isPrimary: true,
                          ),
                        ],
                      ),

                      // Expandable filters
                      if (_showQuestionFilters) ...[
                        SizedBox(height: 12.h),
                        Wrap(
                          spacing: 12.w,
                          runSpacing: 12.h,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Filter dropdown
                            SizedBox(
                              width: 220.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lọc theo chủ đề',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    topics.isEmpty
                                        ? Text(
                                            'Chưa có chủ đề',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey.shade400,
                                            ),
                                          )
                                        : DropdownButtonHideUnderline(
                                            child: DropdownButton<int?>(
                                              value: filterValue,
                                              isExpanded: true,
                                              isDense: true,
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: Colors.grey.shade800,
                                              ),
                                              onChanged:
                                                  questionProvider.isLoading
                                                  ? null
                                                  : (value) {
                                                      questionProvider
                                                          .setTopicFilter(
                                                            value,
                                                          );
                                                    },
                                              items: [
                                                DropdownMenuItem<int?>(
                                                  value: null,
                                                  child: Text('Tất cả chủ đề'),
                                                ),
                                                for (final topic in topics)
                                                  DropdownMenuItem<int?>(
                                                    value: topic.id,
                                                    child: Text(topic.tenChuDe),
                                                  ),
                                              ],
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),

                            // Import topic dropdown
                            SizedBox(
                              width: 180.w,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Chủ đề Excel',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    topics.isEmpty
                                        ? Text(
                                            'Chưa có chủ đề',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey.shade400,
                                            ),
                                          )
                                        : DropdownButtonHideUnderline(
                                            child: DropdownButton<int>(
                                              value: _selectedTopicForImport,
                                              isExpanded: true,
                                              isDense: true,
                                              style: TextStyle(
                                                fontSize: 13.sp,
                                                color: Colors.grey.shade800,
                                              ),
                                              onChanged: _isImportingQuestions
                                                  ? null
                                                  : (value) => setState(
                                                      () =>
                                                          _selectedTopicForImport =
                                                              value,
                                                    ),
                                              items: [
                                                for (final topic in topics)
                                                  DropdownMenuItem<int>(
                                                    value: topic.id,
                                                    child: Text(topic.tenChuDe),
                                                  ),
                                              ],
                                            ),
                                          ),
                                  ],
                                ),
                              ),
                            ),

                            // Import button
                            OutlinedButton.icon(
                              onPressed:
                                  (_isImportingQuestions || topics.isEmpty)
                                  ? null
                                  : _importQuestions,
                              icon: _isImportingQuestions
                                  ? SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Icon(
                                      Icons.upload_file_outlined,
                                      size: 18.sp,
                                    ),
                              label: Text(
                                _isImportingQuestions
                                    ? 'Đang nhập...'
                                    : 'Import Excel',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                // Error message
                if (errorText != null)
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 18.sp,
                          color: Colors.red.shade700,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            errorText,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16.h),

                // Questions List
                Expanded(
                  child: isInitialLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => questionProvider.refreshCauHois(
                            topicId: questionProvider.selectedTopicId,
                          ),
                          child: questions.isEmpty
                              ? ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    SizedBox(height: 80.h),
                                    Center(
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 80.w,
                                            height: 80.w,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.secondary,
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                            ),
                                            child: Icon(
                                              Icons.quiz_outlined,
                                              size: 40.sp,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          Text(
                                            'Chưa có câu hỏi',
                                            style: TextStyle(
                                              fontSize: 16.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          SizedBox(height: 8.h),
                                          Text(
                                            filterValue != null
                                                ? 'Không có câu hỏi cho chủ đề này'
                                                : 'Hãy thêm câu hỏi mới hoặc nhập từ Excel',
                                            style: TextStyle(
                                              fontSize: 13.sp,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount:
                                      questions.length +
                                      (questionProvider.isLoadingMore ||
                                              questionProvider.canLoadMore
                                          ? 1
                                          : 0),
                                  separatorBuilder: (_, __) =>
                                      SizedBox(height: 12.h),
                                  itemBuilder: (context, index) {
                                    if (index >= questions.length) {
                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 16.h,
                                        ),
                                        child: Center(
                                          child: questionProvider.isLoadingMore
                                              ? const CircularProgressIndicator()
                                              : Container(
                                                  height: 48.h,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12.r,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          questionProvider
                                                              .canLoadMore
                                                          ? Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                          : Colors
                                                                .grey
                                                                .shade300,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      onTap:
                                                          questionProvider
                                                              .canLoadMore
                                                          ? () {
                                                              questionProvider
                                                                  .loadMoreCauHois();
                                                            }
                                                          : null,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12.r,
                                                          ),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 24.w,
                                                            ),
                                                        child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.expand_more,
                                                              size: 18.sp,
                                                              color:
                                                                  questionProvider
                                                                      .canLoadMore
                                                                  ? Theme.of(
                                                                          context,
                                                                        )
                                                                        .colorScheme
                                                                        .primary
                                                                  : Colors
                                                                        .grey
                                                                        .shade400,
                                                            ),
                                                            SizedBox(
                                                              width: 8.w,
                                                            ),
                                                            Text(
                                                              'Tải thêm câu hỏi',
                                                              style: TextStyle(
                                                                fontSize: 13.sp,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    questionProvider
                                                                        .canLoadMore
                                                                    ? Theme.of(
                                                                        context,
                                                                      ).colorScheme.primary
                                                                    : Colors
                                                                          .grey
                                                                          .shade400,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      );
                                    }

                                    final question = questions[index];
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.w),
                                        child: Row(
                                          children: [
                                            // Icon
                                            Container(
                                              width: 48.w,
                                              height: 48.w,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.secondary,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              child: Icon(
                                                Icons.quiz_outlined,
                                                size: 24.sp,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 16.w),

                                            // Content
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    question.noiDung,
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade800,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  SizedBox(height: 6.h),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        size: 14.sp,
                                                        color: Colors
                                                            .green
                                                            .shade600,
                                                      ),
                                                      SizedBox(width: 4.w),
                                                      Text(
                                                        'Đáp án: ${question.dapAnDung}',
                                                        style: TextStyle(
                                                          fontSize: 12.sp,
                                                          color: Colors
                                                              .green
                                                              .shade700,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                      SizedBox(width: 12.w),
                                                      Icon(
                                                        Icons.folder_outlined,
                                                        size: 14.sp,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                      SizedBox(width: 4.w),
                                                      Flexible(
                                                        child: Text(
                                                          question
                                                                  .chuDe
                                                                  ?.tenChuDe ??
                                                              '',
                                                          style: TextStyle(
                                                            fontSize: 12.sp,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Actions
                                            PopupMenuButton<String>(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              icon: Icon(
                                                Icons.more_vert,
                                                color: Colors.grey.shade600,
                                                size: 20.sp,
                                              ),
                                              onSelected: (value) {
                                                if (value == 'edit') {
                                                  _showQuestionDialog(
                                                    question: question,
                                                  );
                                                } else if (value == 'delete') {
                                                  _deleteQuestion(question.id);
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                _buildPopupMenuItem(
                                                  'edit',
                                                  Icons.edit_outlined,
                                                  'Sửa',
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                                ),
                                                _buildPopupMenuItem(
                                                  'delete',
                                                  Icons.delete_outline,
                                                  'Xóa',
                                                  Colors.red.shade600,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamsSection() {
    return Consumer2<DeThiProvider, ChuDeProvider>(
      builder: (context, examProvider, topicProvider, _) {
        final response = examProvider.adminDeThis;
        final exams = response?.items ?? const <DeThi>[];
        final topicMap = {
          for (final topic in topicProvider.chuDes) topic.id: topic.tenChuDe,
        };
        final examKeyword = _examKeywordController.text.trim().toLowerCase();
        final filteredExams = exams
            .where((e) {
              final byKeyword = examKeyword.isEmpty
                  ? true
                  : e.tenDeThi.toLowerCase().contains(examKeyword);
              final byTopic = _examTopicFilterId == null
                  ? true
                  : e.chuDeId == _examTopicFilterId;
              final byStatus = _examStatusFilter == null
                  ? true
                  : (e.trangThai == _examStatusFilter);
              return byKeyword && byTopic && byStatus;
            })
            .toList(growable: false);

        return Container(
          color: Colors.grey.shade50,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Search và Filters
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Search field (full width)
                      Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _examKeywordController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(
                              Icons.search,
                              size: 20.sp,
                              color: Colors.grey.shade600,
                            ),
                            suffixIcon: _examKeywordController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      _examKeywordController.clear();
                                      setState(() {});
                                    },
                                    child: Icon(
                                      Icons.clear,
                                      size: 18.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                  )
                                : null,
                            hintText: 'Tìm kiếm đề thi...',
                            hintStyle: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.grey.shade400,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 14.h,
                            ),
                          ),
                          style: TextStyle(fontSize: 13.sp),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      SizedBox(height: 12.h),
                      // Action buttons row
                      Row(
                        children: [
                          // Filter toggle button
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(
                                () => _showExamFilters = !_showExamFilters,
                              );
                            },
                            icon: Icon(
                              _showExamFilters
                                  ? Icons.filter_alt
                                  : Icons.filter_alt_outlined,
                              size: 18.sp,
                            ),
                            label: Text(
                              'Lọc',
                              style: TextStyle(fontSize: 13.sp),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 12.h,
                              ),
                            ),
                          ),
                          const Spacer(),
                          _buildActionButton(
                            onTap: () => _showExamDialog(),
                            icon: Icons.add,
                            label: 'Thêm đề thi',
                            isPrimary: true,
                          ),
                        ],
                      ),

                      // Expandable filters
                      if (_showExamFilters) ...[
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            // Topic filter
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lọc theo chủ đề',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<int?>(
                                        value: _examTopicFilterId,
                                        isExpanded: true,
                                        isDense: true,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey.shade800,
                                        ),
                                        items: [
                                          DropdownMenuItem<int?>(
                                            value: null,
                                            child: Text('Tất cả chủ đề'),
                                          ),
                                          for (final topic
                                              in topicProvider.chuDes)
                                            DropdownMenuItem<int?>(
                                              value: topic.id,
                                              child: Text(topic.tenChuDe),
                                            ),
                                        ],
                                        onChanged: (value) => setState(
                                          () => _examTopicFilterId = value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),

                            // Status filter
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Trạng thái',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    DropdownButtonHideUnderline(
                                      child: DropdownButton<String?>(
                                        value: _examStatusFilter,
                                        isExpanded: true,
                                        isDense: true,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey.shade800,
                                        ),
                                        items: const [
                                          DropdownMenuItem<String?>(
                                            value: null,
                                            child: Text('Tất cả'),
                                          ),
                                          DropdownMenuItem<String?>(
                                            value: 'Mo',
                                            child: Text('Mở'),
                                          ),
                                          DropdownMenuItem<String?>(
                                            value: 'Dong',
                                            child: Text('Đóng'),
                                          ),
                                        ],
                                        onChanged: (value) => setState(
                                          () => _examStatusFilter = value,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),

                            // Clear filters button
                            OutlinedButton.icon(
                              onPressed: () {
                                _examKeywordController.clear();
                                _examTopicFilterId = null;
                                _examStatusFilter = null;
                                setState(() {});
                              },
                              icon: Icon(
                                Icons.filter_alt_off_outlined,
                                size: 18.sp,
                              ),
                              label: Text(
                                'Xoá lọc',
                                style: TextStyle(fontSize: 13.sp),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 12.h,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Exams List
                Expanded(
                  child: examProvider.loadingAdmin
                      ? const Center(child: CircularProgressIndicator())
                      : filteredExams.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 80.h),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 80.w,
                                    height: 80.w,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Icon(
                                      Icons.description_outlined,
                                      size: 40.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'Không tìm thấy đề thi',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    examKeyword.isNotEmpty
                                        ? 'Thử tìm kiếm với từ khóa khác'
                                        : 'Hãy thêm đề thi mới',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: filteredExams.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final exam = filteredExams[index];
                            final topicName =
                                topicMap[exam.chuDeId] ??
                                'Chủ đề ${exam.chuDeId}';
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(16.w),
                                child: Row(
                                  children: [
                                    // Icon
                                    Container(
                                      width: 48.w,
                                      height: 48.w,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.description_outlined,
                                        size: 24.sp,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 16.w),

                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  exam.tenDeThi,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade800,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 8.w,
                                                  vertical: 4.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: exam.trangThai == 'Mo'
                                                      ? Colors.green.shade50
                                                      : Colors.grey.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        6.r,
                                                      ),
                                                  border: Border.all(
                                                    color:
                                                        exam.trangThai == 'Mo'
                                                        ? Colors.green.shade300
                                                        : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Text(
                                                  exam.trangThai == 'Mo'
                                                      ? 'Mở'
                                                      : 'Đóng',
                                                  style: TextStyle(
                                                    fontSize: 11.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        exam.trangThai == 'Mo'
                                                        ? Colors.green.shade700
                                                        : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6.h),
                                          Wrap(
                                            spacing: 12.w,
                                            runSpacing: 4.h,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.folder_outlined,
                                                    size: 14.sp,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    topicName,
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.quiz_outlined,
                                                    size: 14.sp,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    '${exam.soCauHoi} câu',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.timer_outlined,
                                                    size: 14.sp,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    '${exam.thoiGianThi} phút',
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Actions
                                    PopupMenuButton<String>(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          12.r,
                                        ),
                                      ),
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: Colors.grey.shade600,
                                        size: 20.sp,
                                      ),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showExamDialog(exam: exam);
                                        } else if (value == 'delete') {
                                          _deleteExam(exam.id);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        _buildPopupMenuItem(
                                          'edit',
                                          Icons.edit_outlined,
                                          'Sửa',
                                          Theme.of(context).colorScheme.primary,
                                        ),
                                        _buildPopupMenuItem(
                                          'delete',
                                          Icons.delete_outline,
                                          'Xóa',
                                          Colors.red.shade600,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // Pagination
                if (response != null)
                  _buildPagination(
                    response.isLastPage,
                    _examPage,
                    () {
                      setState(() => _examPage--);
                      examProvider.fetchAdminDeThis(page: _examPage);
                    },
                    () {
                      setState(() => _examPage++);
                      examProvider.fetchAdminDeThis(page: _examPage);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactsSection() {
    return Consumer<LienHeProvider>(
      builder: (context, provider, _) {
        final response = provider.allLienHe;
        final contacts = response?.items ?? const <LienHe>[];
        return Container(
          color: Colors.grey.shade50,
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.mail_outline,
                          size: 20.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Tổng ${response?.total ?? contacts.length} liên hệ',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),

                // Contacts List
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : contacts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: 80.h),
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    width: 80.w,
                                    height: 80.w,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Theme.of(context).colorScheme.primary,
                                          Theme.of(
                                            context,
                                          ).colorScheme.secondary,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Icon(
                                      Icons.mail_outline,
                                      size: 40.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    'Chưa có liên hệ',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Text(
                                    'Người dùng chưa gửi liên hệ nào',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: contacts.length,
                          separatorBuilder: (_, __) => SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final contact = contacts[index];
                            final date = UIHelpers.formatDateVN(
                              contact.ngayGui,
                            );
                            final userName =
                                contact.taiKhoan?.fullName.isNotEmpty == true
                                ? contact.taiKhoan!.fullName
                                : (contact.taiKhoan?.userName ??
                                      contact.taiKhoanId);

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () =>
                                      _showContactDetailDialog(contact),
                                  borderRadius: BorderRadius.circular(12.r),
                                  child: Padding(
                                    padding: EdgeInsets.all(16.w),
                                    child: Row(
                                      children: [
                                        // Icon
                                        Container(
                                          width: 48.w,
                                          height: 48.w,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                Theme.of(
                                                  context,
                                                ).colorScheme.secondary,
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.email_outlined,
                                            size: 24.sp,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 16.w),

                                        // Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.tieuDe,
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.grey.shade800,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              SizedBox(height: 6.h),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.person_outline,
                                                    size: 14.sp,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Flexible(
                                                    child: Text(
                                                      userName,
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: Colors
                                                            .grey
                                                            .shade600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4.h),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .calendar_today_outlined,
                                                    size: 14.sp,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                  SizedBox(width: 4.w),
                                                  Text(
                                                    date,
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Delete button
                                        Container(
                                          width: 36.w,
                                          height: 36.w,
                                          decoration: BoxDecoration(
                                            color: Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () =>
                                                  _deleteContact(contact.id),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                              child: Icon(
                                                Icons.delete_outline,
                                                size: 18.sp,
                                                color: Colors.red.shade600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showContactDetailDialog(LienHe contact) async {
    final date = UIHelpers.formatDateVN(contact.ngayGui);
    final userName = contact.taiKhoan?.fullName.isNotEmpty == true
        ? contact.taiKhoan!.fullName
        : (contact.taiKhoan?.userName ?? contact.taiKhoanId);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          constraints: BoxConstraints(maxWidth: 500.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header với gradient
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16.r),
                    topRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        contact.tieuDe,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: Icon(Icons.close, color: Colors.white, size: 20.sp),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info cards
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 18.sp,
                              color: Colors.blue.shade700,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Người gửi',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.email_outlined,
                              size: 18.sp,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  SelectableText(
                                    contact.taiKhoan?.email ?? 'Chưa có email',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.h),

                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 18.sp,
                              color: Colors.orange.shade700,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ngày gửi',
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),
                      Divider(color: Colors.grey.shade300),
                      SizedBox(height: 16.h),

                      // Content section
                      Text(
                        'Nội dung',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: SelectableText(
                          contact.noiDung,
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.6,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16.r),
                    bottomRight: Radius.circular(16.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text('Đóng', style: TextStyle(fontSize: 13.sp)),
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

  Future<void> _searchUsers() async {
    await context.read<UsersProvider>().fetchUsers(
      keyword: _userKeywordController.text.trim().isEmpty
          ? null
          : _userKeywordController.text.trim(),
      page: _userPage,
    );
  }

  Future<void> _showUserDialog(User user) async {
    final rootContext = context;
    final usersProvider = rootContext.read<UsersProvider>();
    final roles = Set<String>.from(user.roles);
    bool isLocked = user.isLocked;

    final result = await showDialog<bool>(
      context: rootContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Quản lý ${user.userName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: roles.any((role) => role.toLowerCase() == 'admin'),
                title: const Text('Quản trị viên'),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      roles.add('Admin');
                    } else {
                      roles.removeWhere(
                        (role) => role.toLowerCase() == 'admin',
                      );
                    }
                  });
                },
              ),
              SwitchListTile(
                value: isLocked,
                title: const Text('Khoá tài khoản'),
                onChanged: (value) => setState(() => isLocked = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Đóng'),
            ),
            FilledButton(
              onPressed: () async {
                await usersProvider.updateRoles(user.id, roles.toList());
                await usersProvider.updateStatus(
                  user.id,
                  trangThaiKhoa: isLocked,
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      // Refresh list to reflect changes
      await usersProvider.fetchUsers(
        keyword: _userKeywordController.text.trim().isEmpty
            ? null
            : _userKeywordController.text.trim(),
        page: _userPage,
      );
      if (rootContext.mounted) {
        ScaffoldMessenger.of(
          rootContext,
        ).showSnackBar(const SnackBar(content: Text('Đã cập nhật người dùng')));
      }
    }
  }

  Future<void> _showTopicDialog({ChuDe? topic}) async {
    final rootContext = context;
    final provider = rootContext.read<ChuDeProvider>();
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: topic?.tenChuDe ?? '');
    final descriptionController = TextEditingController(
      text: topic?.moTa ?? '',
    );

    // Show dialog which only returns the form values. Do not call provider methods
    // while the dialog is still mounted: perform create/update after the dialog
    // has closed to avoid framework assertion about dependents.
    final dialogResult = await showDialog<_TopicDialogResult?>(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(topic == null ? 'Thêm chủ đề' : 'Cập nhật chủ đề'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên chủ đề'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập tên chủ đề'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Mô tả'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              FocusScope.of(dialogContext).unfocus();
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(
                _TopicDialogResult(
                  id: topic?.id,
                  tenChuDe: nameController.text.trim(),
                  moTa: descriptionController.text.trim().isEmpty
                      ? null
                      : descriptionController.text.trim(),
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    // Do not dispose controllers immediately to avoid race with route teardown/IME.

    if (dialogResult == null) return;

    // Perform provider mutation after dialog closed to avoid rebuilds during dialog
    if (dialogResult.isUpdate) {
      final ok = await provider.updateChuDe(
        id: dialogResult.id!,
        tenChuDe: dialogResult.tenChuDe,
        moTa: dialogResult.moTa,
      );
      if (!ok) {
        final error =
            provider.error ?? 'Không thể cập nhật chủ đề. Vui lòng thử lại.';
        if (rootContext.mounted) {
          ScaffoldMessenger.of(
            rootContext,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }
    } else {
      final created = await provider.createChuDe(
        tenChuDe: dialogResult.tenChuDe,
        moTa: dialogResult.moTa,
      );
      if (created == null) {
        final error =
            provider.error ?? 'Không thể tạo chủ đề. Vui lòng thử lại.';
        if (rootContext.mounted) {
          ScaffoldMessenger.of(
            rootContext,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }
    }

    // Refresh the list and show a confirmation
    await provider.fetchChuDes();
    if (rootContext.mounted) {
      ScaffoldMessenger.of(rootContext).showSnackBar(
        SnackBar(
          content: Text(
            dialogResult.isUpdate ? 'Đã cập nhật chủ đề' : 'Đã thêm chủ đề mới',
          ),
        ),
      );
    }
  }

  Future<void> _deleteTopic(int id) async {
    final provider = context.read<ChuDeProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá chủ đề'),
        content: const Text('Bạn có chắc muốn xoá chủ đề này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await provider.deleteChuDe(id);
      if (!mounted) {
        return;
      }
      if (ok) {
        await provider.fetchChuDes();
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xoá chủ đề')));
      } else {
        final message =
            provider.error ?? 'Không thể xoá chủ đề vì đang được sử dụng.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _showQuestionDialog({CauHoi? question}) async {
    final questionProvider = context.read<CauHoiProvider>();
    final topics = context.read<ChuDeProvider>().chuDes;
    final formKey = GlobalKey<FormState>();
    final contentController = TextEditingController(
      text: question?.noiDung ?? '',
    );
    final answerAController = TextEditingController(
      text: question?.dapAnA ?? '',
    );
    final answerBController = TextEditingController(
      text: question?.dapAnB ?? '',
    );
    final answerCController = TextEditingController(
      text: question?.dapAnC ?? '',
    );
    final answerDController = TextEditingController(
      text: question?.dapAnD ?? '',
    );
    final correctController = TextEditingController(
      text: question?.dapAnDung ?? '',
    );
    int selectedTopicId =
        question?.chuDeId ?? (topics.isNotEmpty ? topics.first.id : 0);
    // Show dialog that returns collected values, perform provider calls after
    final dialogResult = await showDialog<_QuestionDialogResult?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(question == null ? 'Thêm câu hỏi' : 'Cập nhật câu hỏi'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedTopicId == 0 && topics.isNotEmpty
                      ? topics.first.id
                      : selectedTopicId,
                  items: [
                    for (final topic in topics)
                      DropdownMenuItem(
                        value: topic.id,
                        child: Text(topic.tenChuDe),
                      ),
                  ],
                  onChanged: (value) =>
                      selectedTopicId = value ?? selectedTopicId,
                  decoration: const InputDecoration(labelText: 'Chủ đề'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Nội dung câu hỏi',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập nội dung'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: answerAController,
                  decoration: const InputDecoration(labelText: 'Đáp án A'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập đáp án A'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: answerBController,
                  decoration: const InputDecoration(labelText: 'Đáp án B'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập đáp án B'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: answerCController,
                  decoration: const InputDecoration(
                    labelText: 'Đáp án C (tuỳ chọn)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: answerDController,
                  decoration: const InputDecoration(
                    labelText: 'Đáp án D (tuỳ chọn)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: correctController,
                  decoration: const InputDecoration(
                    labelText: 'Đáp án đúng (A/B/C/D)',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nhập đáp án đúng'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              FocusScope.of(dialogContext).unfocus();
              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(
                _QuestionDialogResult(
                  id: question?.id,
                  noiDung: contentController.text.trim(),
                  dapAnA: answerAController.text.trim(),
                  dapAnB: answerBController.text.trim(),
                  dapAnC: answerCController.text.trim().isEmpty
                      ? null
                      : answerCController.text.trim(),
                  dapAnD: answerDController.text.trim().isEmpty
                      ? null
                      : answerDController.text.trim(),
                  dapAnDung: correctController.text.trim(),
                  chuDeId: selectedTopicId,
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );

    // Do not dispose controllers immediately to avoid race with route teardown/IME.

    if (dialogResult == null) return;

    if (dialogResult.isUpdate) {
      final ok = await questionProvider.updateCauHoi(
        id: dialogResult.id!,
        noiDung: dialogResult.noiDung,
        dapAnA: dialogResult.dapAnA,
        dapAnB: dialogResult.dapAnB,
        dapAnC: dialogResult.dapAnC,
        dapAnD: dialogResult.dapAnD,
        dapAnDung: dialogResult.dapAnDung,
        chuDeId: dialogResult.chuDeId,
        hinhAnh: question?.hinhAnh,
        amThanh: question?.amThanh,
      );
      if (!ok) {
        final error = questionProvider.error ?? 'Không thể cập nhật câu hỏi.';
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }
    } else {
      final created = await questionProvider.createCauHoi(
        noiDung: dialogResult.noiDung,
        dapAnA: dialogResult.dapAnA,
        dapAnB: dialogResult.dapAnB,
        dapAnC: dialogResult.dapAnC,
        dapAnD: dialogResult.dapAnD,
        dapAnDung: dialogResult.dapAnDung,
        chuDeId: dialogResult.chuDeId,
      );
      if (created == null) {
        final error = questionProvider.error ?? 'Không thể tạo câu hỏi.';
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        }
        return;
      }
    }

    await questionProvider.refreshCauHois(
      topicId: questionProvider.selectedTopicId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dialogResult.isUpdate ? 'Đã cập nhật câu hỏi' : 'Đã thêm câu hỏi',
          ),
        ),
      );
    }
  }

  Future<void> _deleteQuestion(int id) async {
    final questionProvider = context.read<CauHoiProvider>();
    final examProvider = context.read<DeThiProvider>();
    CauHoi? target;
    for (final item in questionProvider.cauHois) {
      if (item.id == id) {
        target = item;
        break;
      }
    }
    if (target == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy câu hỏi để xoá.')),
        );
      }
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá câu hỏi'),
        content: const Text('Bạn có chắc muốn xoá câu hỏi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final topicId = target.chuDeId;
      final currentCount = questionProvider.cauHois
          .where((question) => question.chuDeId == topicId)
          .length;
      final remaining = currentCount - 1;
      final exams = <DeThi>[];
      if (examProvider.adminDeThis?.items != null) {
        exams.addAll(examProvider.adminDeThis!.items);
      }
      exams.addAll(examProvider.openDeThis);

      DeThi? blockingExam;
      for (final exam in exams) {
        if (exam.chuDeId == topicId && exam.soCauHoi > remaining) {
          if (blockingExam == null || exam.soCauHoi > blockingExam.soCauHoi) {
            blockingExam = exam;
          }
        }
      }

      if (blockingExam != null) {
        if (mounted) {
          final available = remaining < 0 ? 0 : remaining;
          final message =
              'Không thể xoá câu hỏi vì đề thi "${blockingExam.tenDeThi}" yêu cầu ${blockingExam.soCauHoi} câu nhưng chủ đề chỉ còn $available câu hỏi.';
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
        return;
      }

      final ok = await questionProvider.deleteCauHoi(id);
      if (!mounted) {
        return;
      }
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xoá câu hỏi')));
      } else {
        final message =
            questionProvider.error ??
            'Không thể xoá câu hỏi. Vui lòng thử lại.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _showExamDialog({DeThi? exam}) async {
    final examProvider = context.read<DeThiProvider>();
    final topics = context.read<ChuDeProvider>().chuDes;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: exam?.tenDeThi ?? '');
    final questionCountController = TextEditingController(
      text: exam?.soCauHoi.toString() ?? '0',
    );
    final durationController = TextEditingController(
      text: exam?.thoiGianThi.toString() ?? '0',
    );
    String status = exam?.trangThai ?? 'Mo';
    bool allowMultipleAttempts = exam?.allowMultipleAttempts ?? true;
    int selectedTopicId =
        exam?.chuDeId ?? (topics.isNotEmpty ? topics.first.id : 0);
    if (selectedTopicId == 0 && topics.isNotEmpty) {
      selectedTopicId = topics.first.id;
    }

    final dialogResult = await showDialog<_ExamDialogResult?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(exam == null ? 'Thêm đề thi' : 'Cập nhật đề thi'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(dialogContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedTopicId,
                    items: [
                      for (final topic in topics)
                        DropdownMenuItem(
                          value: topic.id,
                          child: Text(topic.tenChuDe),
                        ),
                    ],
                    onChanged: (value) => setState(
                      () => selectedTopicId = value ?? selectedTopicId,
                    ),
                    decoration: const InputDecoration(labelText: 'Chủ đề'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Tên đề thi'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nhập tên đề thi'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: questionCountController,
                    decoration: const InputDecoration(labelText: 'Số câu hỏi'),
                    keyboardType: TextInputType.number,
                    validator: (value) => int.tryParse(value ?? '') == null
                        ? 'Nhập số câu hỏi hợp lệ'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Thời gian thi (phút)',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => int.tryParse(value ?? '') == null
                        ? 'Nhập thời gian hợp lệ'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(labelText: 'Trạng thái'),
                    items: const [
                      DropdownMenuItem(value: 'Mo', child: Text('Mở')),
                      DropdownMenuItem(value: 'Dong', child: Text('Đóng')),
                    ],
                    onChanged: (value) =>
                        setState(() => status = value ?? status),
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: allowMultipleAttempts,
                    onChanged: (value) => setState(
                      () => allowMultipleAttempts =
                          value ?? allowMultipleAttempts,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: const Text('Cho phép thí sinh thi nhiều lần'),
                    subtitle: const Text(
                      'Nếu tắt, mỗi tài khoản chỉ được thi và nộp bài một lần.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                FocusScope.of(dialogContext).unfocus();
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop(
                  _ExamDialogResult(
                    id: exam?.id,
                    tenDeThi: nameController.text.trim(),
                    chuDeId: selectedTopicId,
                    soCauHoi: int.parse(questionCountController.text),
                    thoiGianThi: int.parse(durationController.text),
                    trangThai: status,
                    allowMultipleAttempts: allowMultipleAttempts,
                  ),
                );
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );

    // Do not dispose controllers immediately to avoid 'used after disposed' during route teardown.

    if (dialogResult == null) return;

    if (dialogResult.isUpdate) {
      await examProvider.updateDeThi(
        id: dialogResult.id!,
        tenDeThi: dialogResult.tenDeThi,
        chuDeId: dialogResult.chuDeId,
        soCauHoi: dialogResult.soCauHoi,
        thoiGianThi: dialogResult.thoiGianThi,
        trangThai: dialogResult.trangThai,
        allowMultipleAttempts: dialogResult.allowMultipleAttempts,
      );
    } else {
      await examProvider.createDeThi(
        tenDeThi: dialogResult.tenDeThi,
        chuDeId: dialogResult.chuDeId,
        soCauHoi: dialogResult.soCauHoi,
        thoiGianThi: dialogResult.thoiGianThi,
        trangThai: dialogResult.trangThai,
        allowMultipleAttempts: dialogResult.allowMultipleAttempts,
      );
    }

    await examProvider.fetchAdminDeThis(page: _examPage);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dialogResult.isUpdate ? 'Đã cập nhật đề thi' : 'Đã thêm đề thi',
          ),
        ),
      );
    }
  }

  Future<void> _deleteExam(int id) async {
    final examProvider = context.read<DeThiProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá đề thi'),
        content: const Text('Bạn có chắc muốn xoá đề thi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await examProvider.deleteDeThi(id);
      await examProvider.fetchAdminDeThis(page: _examPage);
      if (!mounted) {
        return;
      }
      if (ok) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xoá đề thi')));
      } else {
        final message =
            examProvider.error ?? 'Không thể xoá đề thi vì đang được sử dụng.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  Future<void> _deleteContact(int id) async {
    final provider = context.read<LienHeProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá liên hệ'),
        content: const Text('Bạn có chắc muốn xoá liên hệ này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await provider.deleteLienHe(id);
      if (success) {
        await provider.fetchAll();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xoá liên hệ')));
        }
      } else if (mounted) {
        final message =
            provider.error ?? 'Không thể xoá liên hệ. Vui lòng thử lại sau.';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }
}

class _AdminSection {
  final String title;
  final IconData icon;

  const _AdminSection({required this.title, required this.icon});
}

class _TopicDialogResult {
  final int? id;
  final String tenChuDe;
  final String? moTa;

  const _TopicDialogResult({this.id, required this.tenChuDe, this.moTa});
  bool get isUpdate => id != null;
}

class _QuestionDialogResult {
  final int? id;
  final String noiDung;
  final String dapAnA;
  final String dapAnB;
  final String? dapAnC;
  final String? dapAnD;
  final String dapAnDung;
  final int chuDeId;

  const _QuestionDialogResult({
    this.id,
    required this.noiDung,
    required this.dapAnA,
    required this.dapAnB,
    this.dapAnC,
    this.dapAnD,
    required this.dapAnDung,
    required this.chuDeId,
  });

  bool get isUpdate => id != null;
}

class _ExamDialogResult {
  final int? id;
  final String tenDeThi;
  final int chuDeId;
  final int soCauHoi;
  final int thoiGianThi;
  final String trangThai;
  final bool allowMultipleAttempts;

  const _ExamDialogResult({
    this.id,
    required this.tenDeThi,
    required this.chuDeId,
    required this.soCauHoi,
    required this.thoiGianThi,
    required this.trangThai,
    required this.allowMultipleAttempts,
  });

  bool get isUpdate => id != null;
}
