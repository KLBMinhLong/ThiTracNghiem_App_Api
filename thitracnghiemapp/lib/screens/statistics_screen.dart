import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ket_qua_thi.dart';
import '../providers/auth_provider.dart';
import '../providers/ket_qua_thi_provider.dart';
import '../providers/chu_de_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _load();
    }
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id;
    await Future.wait([
      context.read<KetQuaThiProvider>().fetchKetQuaThiList(onlyUserId: userId),
      context.read<ChuDeProvider>().fetchChuDes(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thống kê kết quả')),
      body: Consumer<KetQuaThiProvider>(
        builder: (context, provider, _) {
          final items =
              provider.ketQuaThiList?.items
                  .where((e) => e.diem != null)
                  .toList(growable: false) ??
              const <KetQuaThiSummary>[];

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (provider.isLoading && items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                if (!provider.isLoading && items.isEmpty) _buildEmpty(),
                if (items.isNotEmpty) ...[
                  _ScoreOverTimeCard(items: items),
                  const SizedBox(height: 16),
                  _AverageByTopicCard(items: items),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Column(
      children: const [
        Icon(Icons.stacked_bar_chart_outlined, size: 64),
        SizedBox(height: 12),
        Text('Chưa có dữ liệu thống kê'),
        SizedBox(height: 4),
        Text(
          'Hãy hoàn thành một bài thi để xem biểu đồ điểm và xu hướng.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }
}

class _ScoreOverTimeCard extends StatelessWidget {
  final List<KetQuaThiSummary> items;

  const _ScoreOverTimeCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) => a.ngayThi.compareTo(b.ngayThi));
    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final score = sorted[i].diem ?? 0;
      spots.add(FlSpot(i.toDouble(), score));
    }
    final maxScore = (spots.map((s) => s.y).fold<double>(0, max)).clamp(0, 10);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điểm theo thời gian',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: max(10, maxScore + 1),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.black12),
                      bottom: BorderSide(color: Colors.black12),
                      right: BorderSide(color: Colors.transparent),
                      top: BorderSide(color: Colors.transparent),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          final date = sorted[i].ngayThi;
                          final text = '${date.day}/${date.month}';
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        interval: (sorted.length / 6).clamp(1, 6).toDouble(),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 28,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      spots: spots,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AverageByTopicCard extends StatelessWidget {
  final List<KetQuaThiSummary> items;

  const _AverageByTopicCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final chuDes = context.watch<ChuDeProvider>().chuDes;
    String topicNameFor(KetQuaThiSummary e) {
      final nested = e.deThi?.chuDe?.tenChuDe;
      if (nested != null && nested.isNotEmpty) return nested;
      final id = e.deThi?.chuDeId;
      if (id != null && id != 0) {
        final found = chuDes.where((c) => c.id == id).toList(growable: false);
        if (found.isNotEmpty) return found.first.tenChuDe;
      }
      return 'Khác';
    }

    final byTopic = <String, List<double>>{};
    for (final e in items) {
      final topic = topicNameFor(e);
      final score = e.diem;
      if (score == null) continue;
      byTopic.putIfAbsent(topic, () => <double>[]).add(score);
    }
    final averages =
        byTopic.entries
            .map(
              (e) => MapEntry(
                e.key,
                e.value.isEmpty
                    ? 0.0
                    : (e.value.reduce((a, b) => a + b) / e.value.length),
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Limit to top 8 topics for clarity
    final top = averages.take(8).toList(growable: false);

    if (top.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Điểm trung bình theo chủ đề',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              const Text('Chưa có dữ liệu theo chủ đề.'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Điểm trung bình theo chủ đề',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: max(200, 40.0 * top.length),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceBetween,
                  maxY: 10,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 60,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= top.length) {
                            return const SizedBox.shrink();
                          }
                          final label = top[index].key;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: SizedBox(
                              width: 64,
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < top.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: top[i].value,
                            color: Theme.of(context).colorScheme.primary,
                            width: 14,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
