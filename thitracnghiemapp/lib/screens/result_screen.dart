import 'package:flutter/material.dart';

import '../models/de_thi.dart';
import '../models/quiz_session.dart';

class ResultScreen extends StatelessWidget {
  final DeThi deThi;
  final SubmitThiResult result;

  const ResultScreen({super.key, required this.deThi, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả bài thi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deThi.tenDeThi,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: [
                      _SummaryChip(
                        label: 'Điểm',
                        value: result.diem.toStringAsFixed(2),
                        icon: Icons.grade_outlined,
                      ),
                      _SummaryChip(
                        label: 'Số câu đúng',
                        value: '${result.soCauDung}/${result.tongSoCau}',
                        icon: Icons.check_circle_outline,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (result.chiTiet.isNotEmpty)
            Card(
              child: ExpansionTile(
                initiallyExpanded: true,
                title: const Text('Chi tiết từng câu hỏi'),
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: result.chiTiet.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final detail = result.chiTiet[index];
                      final isCorrect = detail.dungHaySai == true;
                      return ListTile(
                        title: Text('Câu ${index + 1}: ${detail.noiDung}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đáp án đã chọn: ${detail.dapAnChon ?? 'Chưa chọn'}',
                            ),
                            Text('Đáp án đúng: ${detail.dapAnDung}'),
                          ],
                        ),
                        trailing: Icon(
                          isCorrect
                              ? Icons.check_circle
                              : Icons.cancel_outlined,
                          color: isCorrect
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Về trang chủ'),
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
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
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
