import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/de_thi.dart';
import '../models/quiz_session.dart';
import '../providers/thi_provider.dart';
import 'result_screen.dart';

class QuizScreen extends StatefulWidget {
  final DeThi deThi;

  const QuizScreen({super.key, required this.deThi});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialiseSession();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    context.read<ThiProvider>().reset();
    super.dispose();
  }

  Future<void> _initialiseSession() async {
    final provider = context.read<ThiProvider>();
    if (provider.currentSession == null) {
      await provider.startThi(widget.deThi.id);
    }
    if (!mounted) {
      return;
    }
    final session = provider.currentSession;
    if (session != null) {
      _currentIndex = 0;
      _startTimer(session.thoiGianThi * 60);
    } else if (provider.error != null) {
      final friendlyMessage = provider.error!.length > 200
          ? 'Không thể tải bài thi. Vui lòng thử lại sau.'
          : provider.error!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(friendlyMessage)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldLeave = await _confirmExit(context);
        if (shouldLeave) {
          context.read<ThiProvider>().reset();
        }
        return shouldLeave;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.deThi.tenDeThi),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Consumer<ThiProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return _ErrorView(
                message: provider.error!,
                onRetry: () => provider.startThi(widget.deThi.id),
              );
            }

            final session = provider.currentSession;
            if (session == null || session.cauHois.isEmpty) {
              return const Center(child: Text('Không có câu hỏi để hiển thị'));
            }

            if (_remainingSeconds == 0) {
              _startTimer(session.thoiGianThi * 60);
            }

            _currentIndex = _currentIndex.clamp(0, session.cauHois.length - 1);
            final question = session.cauHois[_currentIndex];

            return Column(
              children: [
                _ProgressHeader(
                  current: _currentIndex + 1,
                  total: session.cauHois.length,
                  onJumpTo: (index) => setState(() => _currentIndex = index),
                  questions: session.cauHois,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _QuestionBody(
                      question: question,
                      onSelect: (answer) =>
                          _selectAnswer(provider, question, answer),
                    ),
                  ),
                ),
                _QuizControls(
                  canGoBack: _currentIndex > 0,
                  canGoNext: _currentIndex < session.cauHois.length - 1,
                  onBack: () => setState(() => _currentIndex--),
                  onNext: () => setState(() => _currentIndex++),
                  onSubmit: _submitting ? null : () => _submit(provider),
                  isLast: _currentIndex == session.cauHois.length - 1,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _selectAnswer(
    ThiProvider provider,
    QuizQuestion question,
    String answer,
  ) async {
    await provider.updateDapAn(cauHoiId: question.id, dapAnChon: answer);
    final error = provider.error;
    if (mounted && error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _submit(ThiProvider provider) async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    await provider.submitThi();
    setState(() => _submitting = false);
    final result = provider.submitResult;
    if (!mounted || result == null) {
      return;
    }
    _timer?.cancel();
    provider.reset();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(deThi: widget.deThi, result: result),
      ),
    );
  }

  void _startTimer(int seconds) {
    if (seconds <= 0) {
      return;
    }
    _timer?.cancel();
    setState(() => _remainingSeconds = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
        final provider = context.read<ThiProvider>();
        _submit(provider);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String _formatTime(int seconds) {
    final clamped = seconds < 0 ? 0 : seconds;
    final minutes = clamped ~/ 60;
    final remaining = clamped % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remaining.toString().padLeft(2, '0')}';
  }

  Future<bool> _confirmExit(BuildContext context) async {
    final provider = context.read<ThiProvider>();
    if (provider.currentSession == null) {
      return true;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thoát bài thi?'),
        content: const Text('Tiến trình hiện tại sẽ không được lưu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tiếp tục'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final displayMessage = message.length > 300
        ? 'Không thể tải bài thi. Vui lòng thử lại sau.'
        : message;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(displayMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Thử lại')),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int current;
  final int total;
  final List<QuizQuestion> questions;
  final ValueChanged<int> onJumpTo;

  const _ProgressHeader({
    required this.current,
    required this.total,
    required this.questions,
    required this.onJumpTo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Câu hỏi $current/$total',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: total,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final question = questions[index];
                final answered = question.selectedAnswer != null;
                return GestureDetector(
                  onTap: () => onJumpTo(index),
                  child: CircleAvatar(
                    backgroundColor: index == current - 1
                        ? Theme.of(context).colorScheme.primary
                        : answered
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surfaceVariant,
                    foregroundColor: index == current - 1
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                    child: Text('${index + 1}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBody extends StatelessWidget {
  final QuizQuestion question;
  final ValueChanged<String> onSelect;

  const _QuestionBody({required this.question, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final answers = <MapEntry<String, String?>>[
      MapEntry('A', question.dapAnA),
      MapEntry('B', question.dapAnB),
      MapEntry('C', question.dapAnC),
      MapEntry('D', question.dapAnD),
    ].where((entry) => entry.value != null && entry.value!.isNotEmpty);

    return ListView(
      children: [
        Text(question.noiDung, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        for (final entry in answers)
          Card(
            child: RadioListTile<String>(
              value: entry.key,
              groupValue: question.selectedAnswer,
              title: Text(entry.value!),
              onChanged: (value) {
                if (value != null) {
                  onSelect(value);
                }
              },
            ),
          ),
      ],
    );
  }
}

class _QuizControls extends StatelessWidget {
  final bool canGoBack;
  final bool canGoNext;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onSubmit;
  final bool isLast;

  const _QuizControls({
    required this.canGoBack,
    required this.canGoNext,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: canGoBack ? onBack : null,
              child: const Text('Trước'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: isLast ? onSubmit : (canGoNext ? onNext : null),
              child: Text(isLast ? 'Nộp bài' : 'Tiếp'),
            ),
          ),
        ],
      ),
    );
  }
}
