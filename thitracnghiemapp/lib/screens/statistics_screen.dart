import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        title: Text(
          'Thống kê kết quả',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
      ),
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
              padding: EdgeInsets.all(16.w),
              children: [
                if (provider.isLoading && items.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 48.h),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                if (!provider.isLoading && items.isEmpty) _buildEmpty(),
                if (items.isNotEmpty) ...[
                  _buildSummaryCards(items),
                  SizedBox(height: 16.h),
                  _ScoreOverTimeCard(items: items),
                  SizedBox(height: 16.h),
                  _AverageByTopicCard(items: items),
                ],
                SizedBox(height: 24.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(List<KetQuaThiSummary> items) {
    final totalTests = items.length;
    final avgScore = items.isEmpty
        ? 0.0
        : items.map((e) => e.diem ?? 0).reduce((a, b) => a + b) / items.length;
    final maxScore = items.isEmpty
        ? 0.0
        : items.map((e) => e.diem ?? 0).reduce(max);

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.quiz_outlined,
            label: 'Tổng bài thi',
            value: totalTests.toString(),
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _SummaryCard(
            icon: Icons.analytics_outlined,
            label: 'Điểm TB',
            value: avgScore.toStringAsFixed(1),
            color: Colors.orange,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _SummaryCard(
            icon: Icons.emoji_events_outlined,
            label: 'Cao nhất',
            value: maxScore.toStringAsFixed(1),
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48.h),
        child: Column(
          children: [
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(
                Icons.stacked_bar_chart_outlined,
                size: 50.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Chưa có dữ liệu thống kê',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'Hãy hoàn thành một bài thi để xem biểu đồ điểm và xu hướng.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color],
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, size: 22.sp, color: Colors.white),
          ),
          SizedBox(height: 10.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    Icons.show_chart,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'Điểm theo thời gian',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            SizedBox(
              height: 240.h,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: max(10, maxScore + 1),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300, width: 1),
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      right: const BorderSide(color: Colors.transparent),
                      top: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28.h,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= sorted.length) {
                            return const SizedBox.shrink();
                          }
                          final date = sorted[i].ngayThi;
                          final text = '${date.day}/${date.month}';
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Padding(
                              padding: EdgeInsets.only(top: 6.h),
                              child: Text(
                                text,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
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
                        reservedSize: 32.w,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
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
                      curveSmoothness: 0.35,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2.5,
                            strokeColor: Theme.of(context).colorScheme.primary,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.15),
                            Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
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
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                      Icons.bar_chart,
                      size: 20.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Điểm trung bình theo chủ đề',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Chưa có dữ liệu theo chủ đề.',
                style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                    Icons.bar_chart,
                    size: 20.sp,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    'Điểm trung bình theo chủ đề',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            SizedBox(
              height: max(200.0, 45.0 * top.length),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 10,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 2,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(color: Colors.grey.shade300, width: 1),
                      bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      right: const BorderSide(color: Colors.transparent),
                      top: const BorderSide(color: Colors.transparent),
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 32.w,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24.h,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= top.length) {
                            return const SizedBox.shrink();
                          }
                          final avg = top[index].value;
                          return Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: Text(
                              avg.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 64.h,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= top.length) {
                            return const SizedBox.shrink();
                          }
                          final label = top[index].key;
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: SizedBox(
                              width: 64.w,
                              child: Padding(
                                padding: EdgeInsets.only(top: 6.h),
                                child: Text(
                                  label,
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade600,
                                    height: 1.2,
                                  ),
                                ),
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
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            width: 18,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(6.r),
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
