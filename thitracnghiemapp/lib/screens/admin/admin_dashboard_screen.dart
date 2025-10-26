import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final TextEditingController _userKeywordController = TextEditingController();
  int _selectedIndex = 0;
  int _userPage = 1;
  int _examPage = 1;
  bool _isImportingQuestions = false;
  int? _selectedTopicForImport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _userKeywordController.dispose();
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
          appBar: AppBar(title: const Text('Bảng điều khiển quản trị')),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) =>
                          setState(() => _selectedIndex = index),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        for (final section in sections)
                          NavigationRailDestination(
                            icon: Icon(section.icon),
                            label: Text(section.title),
                          ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: body),
                    NavigationBar(
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: (index) =>
                          setState(() => _selectedIndex = index),
                      destinations: [
                        for (final section in sections)
                          NavigationDestination(
                            icon: Icon(section.icon),
                            label: section.title,
                          ),
                      ],
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userKeywordController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Tìm kiếm theo tên hoặc email',
                      ),
                      onSubmitted: (_) => _searchUsers(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _searchUsers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tải lại'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (response == null)
                const Expanded(
                  child: Center(child: Text('Không có dữ liệu người dùng')),
                )
              else
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _searchUsers,
                    child: ListView.separated(
                      itemCount: response.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = response.items[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              user.fullName.isNotEmpty
                                  ? user.fullName
                                  : user.userName,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.email),
                                Text('Quyền: ${user.roles.join(', ')}'),
                                Text(user.isLocked ? 'Đã khoá' : 'Hoạt động'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _showUserDialog(user),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              if (response != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _userPage > 1
                          ? () {
                              setState(() => _userPage--);
                              provider.fetchUsers(
                                keyword: _userKeywordController.text.trim(),
                                page: _userPage,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Trang $_userPage'),
                    IconButton(
                      onPressed: response.isLastPage
                          ? null
                          : () {
                              setState(() => _userPage++);
                              provider.fetchUsers(
                                keyword: _userKeywordController.text.trim(),
                                page: _userPage,
                              );
                            },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopicsSection() {
    return Consumer<ChuDeProvider>(
      builder: (context, provider, _) {
        final topics = provider.chuDes;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showTopicDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm chủ đề'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: topics.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final topic = topics[index];
                          return Card(
                            child: ListTile(
                              title: Text(topic.tenChuDe),
                              subtitle: Text(topic.moTa ?? 'Không có mô tả'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _showTopicDialog(topic: topic),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteTopic(topic.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
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

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.end,
                  children: [
                    SizedBox(
                      width: 240,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Lọc câu hỏi theo chủ đề',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: topics.isEmpty
                            ? const Text('Chưa có chủ đề')
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: filterValue,
                                  isExpanded: true,
                                  onChanged: questionProvider.isLoading
                                      ? null
                                      : (value) {
                                          questionProvider.setTopicFilter(
                                            value,
                                          );
                                        },
                                  items: [
                                    DropdownMenuItem<int?>(
                                      value: null,
                                      child: const Text('Tất cả chủ đề'),
                                    ),
                                    for (final topic in topics)
                                      DropdownMenuItem<int?>(
                                        value: topic.id,
                                        child: Text(topic.tenChuDe),
                                      ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Chủ đề cho file Excel',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        child: topics.isEmpty
                            ? const Text('Chưa có chủ đề')
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedTopicForImport,
                                  isExpanded: true,
                                  onChanged: _isImportingQuestions
                                      ? null
                                      : (value) => setState(
                                          () => _selectedTopicForImport = value,
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
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _isImportingQuestions || topics.isEmpty
                          ? null
                          : _importQuestions,
                      icon: _isImportingQuestions
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file_outlined),
                      label: Text(
                        _isImportingQuestions
                            ? 'Đang nhập...'
                            : 'Nhập từ Excel',
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _showQuestionDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Thêm câu hỏi'),
                    ),
                  ],
                ),
              ),
              if (errorText != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      errorText,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Expanded(
                child: isInitialLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () => questionProvider.refreshCauHois(
                          topicId: questionProvider.selectedTopicId,
                        ),
                        child: questions.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(
                                    height: 240,
                                    child: Center(
                                      child: Text('Không có câu hỏi phù hợp.'),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount:
                                    questions.length +
                                    (questionProvider.isLoadingMore ||
                                            questionProvider.canLoadMore
                                        ? 1
                                        : 0),
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  if (index >= questions.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Center(
                                        child: questionProvider.isLoadingMore
                                            ? const CircularProgressIndicator()
                                            : OutlinedButton.icon(
                                                onPressed:
                                                    questionProvider.canLoadMore
                                                    ? () {
                                                        questionProvider
                                                            .loadMoreCauHois();
                                                      }
                                                    : null,
                                                icon: const Icon(
                                                  Icons.expand_more,
                                                ),
                                                label: const Text(
                                                  'Tải thêm câu hỏi',
                                                ),
                                              ),
                                      ),
                                    );
                                  }

                                  final question = questions[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(question.noiDung),
                                      subtitle: Text(
                                        'Đáp án đúng: ${question.dapAnDung} | Chủ đề: ${question.chuDe?.tenChuDe ?? ''}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed: () =>
                                                _showQuestionDialog(
                                                  question: question,
                                                ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            onPressed: () =>
                                                _deleteQuestion(question.id),
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

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showExamDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm đề thi'),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: examProvider.loadingAdmin
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: exams.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final exam = exams[index];
                          final topicName =
                              topicMap[exam.chuDeId] ??
                              'Chủ đề ${exam.chuDeId}';
                          return Card(
                            child: ListTile(
                              title: Text(exam.tenDeThi),
                              subtitle: Text(
                                'Chủ đề: $topicName | Số câu: ${exam.soCauHoi} | Thời gian: ${exam.thoiGianThi} phút | Trạng thái: ${exam.trangThai}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () =>
                                        _showExamDialog(exam: exam),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteExam(exam.id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (response != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _examPage > 1
                          ? () {
                              setState(() => _examPage--);
                              examProvider.fetchAdminDeThis(page: _examPage);
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Trang $_examPage'),
                    IconButton(
                      onPressed: response.isLastPage
                          ? null
                          : () {
                              setState(() => _examPage++);
                              examProvider.fetchAdminDeThis(page: _examPage);
                            },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
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
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tổng ${response?.total ?? contacts.length} liên hệ'),
              const SizedBox(height: 16),
              Expanded(
                child: provider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        itemCount: contacts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final contact = contacts[index];
                          final date = MaterialLocalizations.of(
                            context,
                          ).formatFullDate(contact.ngayGui);
                          return Card(
                            child: ListTile(
                              title: Text(contact.tieuDe),
                              subtitle: Text(
                                '${contact.noiDung}\nNgười gửi: ${contact.taiKhoan?.userName ?? contact.taiKhoanId}\nNgày: $date',
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: () => _deleteContact(contact.id),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
                    () =>
                        allowMultipleAttempts = value ?? allowMultipleAttempts,
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
