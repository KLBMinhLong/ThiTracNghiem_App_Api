import 'package:flutter/material.dart';
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
import 'admin/admin_dashboard_screen.dart';
import 'exam_detail_screen.dart';
import 'login_screen.dart';
import 'result_review_screen.dart';

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
    final titles = ['Đề thi', 'Lịch sử thi', 'Hộp thư góp ý', 'Hồ sơ cá nhân'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentTab]),
        actions: [
          if (auth.isAdmin)
            IconButton(
              tooltip: 'Trang quản trị',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
              ),
            ),
        ],
      ),
      body: _initializing
          ? const Center(child: CircularProgressIndicator())
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
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            label: 'Đề thi',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            label: 'Lịch sử',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            label: 'Liên hệ',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext dialogContext) async {
    final shouldLogout = await showDialog<bool>(
      context: dialogContext,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) {
      return;
    }

    await dialogContext.read<AuthProvider>().logout();
    if (!mounted) {
      return;
    }

    Navigator.of(dialogContext).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget? _buildFab() {
    if (_currentTab == 2) {
      return FloatingActionButton.extended(
        onPressed: () => _showCreateContact(context),
        icon: const Icon(Icons.add_comment),
        label: const Text('Liên hệ mới'),
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
    final lienHeProvider = context.read<LienHeProvider>();
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final hostContext = context;

    try {
      final formResult = await showModalBottomSheet<_ContactFormResult?>(
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
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Tiêu đề'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập tiêu đề'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contentController,
                        decoration: const InputDecoration(
                          labelText: 'Nội dung',
                        ),
                        minLines: 3,
                        maxLines: 6,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Vui lòng nhập nội dung'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
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
                        child: const Text('Gửi liên hệ'),
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

      await lienHeProvider.createLienHe(
        tieuDe: formResult.title,
        noiDung: formResult.content,
      );

      if (!mounted) {
        return;
      }
      final error = lienHeProvider.error;
      if (error != null) {
        ScaffoldMessenger.of(
          hostContext,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      ScaffoldMessenger.of(hostContext).showSnackBar(
        const SnackBar(content: Text('Đã gửi liên hệ thành công')),
      );
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
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm theo tên đề thi hoặc chủ đề',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: keyword.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => searchController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Tất cả'),
                    selected: selected == null,
                    onSelected: (_) => onTopicSelected(null),
                  ),
                  for (final chuDe in chuDeProvider.chuDes)
                    FilterChip(
                      label: Text(chuDe.tenChuDe),
                      selected: selected == chuDe.id,
                      onSelected: (_) => onTopicSelected(chuDe.id),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (deThiProvider.loadingOpen)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: Text('Không tìm thấy đề thi phù hợp.')),
                )
              else
                ...items.map(
                  (deThi) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(deThi.tenDeThi),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chủ đề: ${topicNameFor(deThi)}'),
                          Text(
                            'Thời gian: ${deThi.thoiGianThi} phút | ${deThi.soCauHoi} câu',
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onOpenExam(deThi),
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
    return Consumer<KetQuaThiProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () => provider.fetchKetQuaThiList(
            page: provider.ketQuaThiList?.page ?? 1,
            onlyUserId: restrictToUserId,
          ),
          child: provider.isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  children: const [Center(child: CircularProgressIndicator())],
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 48,
                      ),
                      children: const [
                        Center(child: Icon(Icons.history_toggle_off, size: 48)),
                        SizedBox(height: 12),
                        Text(
                          'Chưa có lịch sử thi',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final summary = list[index];
                      final statusColor = summary.isCompleted
                          ? Colors.green
                          : Theme.of(context).colorScheme.secondary;
                      final dateString = MaterialLocalizations.of(
                        context,
                      ).formatFullDate(summary.ngayThi);
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
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Xoá lịch sử thi'),
                              content: const Text(
                                'Bạn có chắc chắn muốn xoá kết quả này?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Huỷ'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Xoá'),
                                ),
                              ],
                            ),
                          );
                          if (confirm != true) return false;

                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await context
                              .read<KetQuaThiProvider>()
                              .deleteKetQuaThi(summary.id);
                          if (ok) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Đã xoá lịch sử thi'),
                              ),
                            );
                          } else {
                            final msg =
                                context.read<KetQuaThiProvider>().error ??
                                'Không thể xoá lịch sử thi. Vui lòng thử lại.';
                            messenger.showSnackBar(
                              SnackBar(content: Text(msg)),
                            );
                          }
                          return ok;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          color: Theme.of(context).colorScheme.error,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          child: ListTile(
                            title: Text(
                              summary.deThi?.tenDeThi ??
                                  'Đề thi #${summary.id}',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ngày thi: $dateString'),
                                if (summary.diem != null)
                                  Text(
                                    'Điểm: ${summary.diem!.toStringAsFixed(2)}',
                                  ),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(summary.trangThai),
                              backgroundColor: statusColor.withOpacity(0.15),
                              labelStyle: TextStyle(color: statusColor),
                            ),
                            onTap: () => onViewDetail(summary),
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
    return Consumer<LienHeProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () => provider.fetchMine(),
          child: () {
            if (provider.isLoading && provider.myLienHe == null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 48),
                children: const [Center(child: CircularProgressIndicator())],
              );
            }
            if (provider.error != null) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        provider.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            final items = provider.myLienHe ?? const <LienHe>[];
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 48,
                ),
                children: const [
                  Center(
                    child: Icon(Icons.mark_email_unread_outlined, size: 48),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Chưa có liên hệ nào. Hãy gửi góp ý đầu tiên!',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final lienHe = items[index];
                final date = MaterialLocalizations.of(
                  context,
                ).formatFullDate(lienHe.ngayGui);
                return Dismissible(
                  key: ValueKey(lienHe.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Xoá liên hệ'),
                        content: const Text(
                          'Bạn có chắc muốn xoá liên hệ này?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Huỷ'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Xoá'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) {
                      return false;
                    }
                    final messenger = ScaffoldMessenger.of(context);
                    final success = await provider.deleteLienHe(lienHe.id);
                    if (success) {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Đã xoá liên hệ')),
                      );
                    } else {
                      final message =
                          provider.error ??
                          'Không thể xoá liên hệ. Vui lòng thử lại.';
                      messenger.showSnackBar(SnackBar(content: Text(message)));
                    }
                    return success;
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: Theme.of(context).colorScheme.error,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    child: ListTile(
                      title: Text(lienHe.tieuDe),
                      subtitle: Text('${lienHe.noiDung}\nNgày gửi: $date'),
                      isThreeLine: true,
                      onTap: () => _showEditContact(context, lienHe),
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
    final provider = rootContext.read<LienHeProvider>();
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: lienHe.tieuDe);
    final contentController = TextEditingController(text: lienHe.noiDung);

    final result = await showModalBottomSheet<_ContactFormResult?>(
      context: rootContext,
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
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Tiêu đề'),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập tiêu đề'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contentController,
                      decoration: const InputDecoration(labelText: 'Nội dung'),
                      minLines: 3,
                      maxLines: 6,
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Vui lòng nhập nội dung'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
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
                      child: const Text('Lưu thay đổi'),
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
    await provider.updateLienHe(
      id: lienHe.id,
      tieuDe: result.title,
      noiDung: result.content,
    );
    if (provider.error != null && rootContext.mounted) {
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(SnackBar(content: Text(provider.error!)));
      return;
    }
    if (rootContext.mounted) {
      ScaffoldMessenger.of(
        rootContext,
      ).showSnackBar(const SnackBar(content: Text('Đã cập nhật liên hệ')));
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
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Không tìm thấy thông tin người dùng'));
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                user.fullName.isNotEmpty
                    ? user.fullName[0].toUpperCase()
                    : user.userName[0].toUpperCase(),
              ),
            ),
            title: Text(
              user.fullName.isNotEmpty ? user.fullName : user.userName,
            ),
            subtitle: Text(user.email),
          ),
        ),
        const SizedBox(height: 24),
        Text('Tài khoản', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Chỉnh sửa thông tin'),
                onTap: () => onEditProfile(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_reset_outlined),
                title: const Text('Đổi mật khẩu'),
                onTap: () => onChangePassword(context),
              ),
              const Divider(height: 1),
              _TwoFaTile(),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Cài đặt', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Chế độ tối'),
                value: Theme.of(context).brightness == Brightness.dark,
                onChanged: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tính năng sẽ sớm được hỗ trợ.'),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Thông báo hoạt động'),
                value: true,
                onChanged: (_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tính năng thông báo đang được phát triển.',
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Đăng xuất'),
                onTap: () => onLogout(context),
              ),
            ],
          ),
        ),
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
                            : 'Ngày sinh: ${MaterialLocalizations.of(context).formatFullDate(_birthday!)}',
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
