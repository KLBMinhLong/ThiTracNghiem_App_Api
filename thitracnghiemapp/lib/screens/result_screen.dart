import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/de_thi.dart';
import '../models/quiz_session.dart';
import '../utils/ui_helpers.dart';

class ResultScreen extends StatelessWidget {
  final DeThi deThi;
  final SubmitThiResult result;

  const ResultScreen({super.key, required this.deThi, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (result.soCauDung / result.tongSoCau * 100).round();
    final isPassed = percentage >= 50;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kết quả bài thi'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // Score Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isPassed
                      ? [Colors.green.shade400, Colors.green.shade600]
                      : [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
              ),
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // Success/Try Again Icon
                  Container(
                    width: 80.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPassed
                          ? Icons.celebration_outlined
                          : Icons.refresh_outlined,
                      size: 40.sp,
                      color: Colors.white,
                    ),
                  ),
                  UIHelpers.verticalSpaceMedium(),

                  // Status Text
                  Text(
                    isPassed ? 'Chúc mừng!' : 'Hãy cố gắng hơn!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    isPassed
                        ? 'Bạn đã vượt qua bài thi'
                        : 'Bạn chưa đạt yêu cầu',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14.sp,
                    ),
                  ),
                  UIHelpers.verticalSpaceLarge(),

                  // Score Display
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Điểm số',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          result.diem.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 48.sp,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/10',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 16.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          UIHelpers.verticalSpaceLarge(),

          // Exam Info
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40.w,
                        height: 40.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.quiz,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      UIHelpers.horizontalSpaceMedium(),
                      Expanded(
                        child: Text(
                          deThi.tenDeThi,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  UIHelpers.verticalSpaceLarge(),

                  // Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Câu đúng',
                          value: '${result.soCauDung}',
                          total: '/${result.tongSoCau}',
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.cancel_outlined,
                          label: 'Câu sai',
                          value: '${result.tongSoCau - result.soCauDung}',
                          total: '/${result.tongSoCau}',
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.percent_outlined,
                          label: 'Tỷ lệ đúng',
                          value: '$percentage',
                          total: '%',
                          color: Colors.blue,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.quiz_outlined,
                          label: 'Tổng câu',
                          value: '${result.tongSoCau}',
                          total: '',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          UIHelpers.verticalSpaceMedium(),

          // Question Details
          if (result.chiTiet.isNotEmpty)
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  childrenPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  leading: Container(
                    width: 40.w,
                    height: 40.h,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.list_alt_outlined,
                      color: theme.colorScheme.primary,
                      size: 20.sp,
                    ),
                  ),
                  title: Text(
                    'Chi tiết từng câu hỏi',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                  children: [
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: result.chiTiet.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1.h, indent: 20.w, endIndent: 20.w),
                      itemBuilder: (context, index) {
                        final detail = result.chiTiet[index];
                        final isCorrect = detail.dungHaySai == true;

                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 16.h,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question Number
                              Container(
                                width: 32.w,
                                height: 32.h,
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green.withValues(alpha: 0.1)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      color: isCorrect
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              UIHelpers.horizontalSpaceMedium(),

                              // Question Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      detail.noiDung,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.person_outline,
                                          size: 14.sp,
                                          color: Colors.grey.shade600,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Bạn chọn: ',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          detail.dapAnChon ?? 'Chưa chọn',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: detail.dapAnChon == null
                                                ? Colors.grey
                                                : (isCorrect
                                                      ? Colors.green.shade700
                                                      : Colors.red.shade700),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 4.h),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 14.sp,
                                          color: Colors.green.shade600,
                                        ),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Đáp án đúng: ',
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        Text(
                                          detail.dapAnDung,
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Status Icon
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect
                                    ? Colors.green.shade600
                                    : Colors.red.shade600,
                                size: 28.sp,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

          SizedBox(height: 100.h), // Space for bottom button
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        child: FilledButton.icon(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: Icon(Icons.home_outlined, size: 20.sp),
          label: Text(
            'Về trang chủ',
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
          style: FilledButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16.h),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String total;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.sp, color: color),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 1,
                ),
              ),
              if (total.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Text(
                    total,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
