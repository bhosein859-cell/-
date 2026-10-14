import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/problem.dart';

/// نشان وضعیت مسئله — مسائل بسته/حل‌شده با نشان سبز «انجام شده».
class ProblemStatusBadge extends StatelessWidget {
  const ProblemStatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final bool done = status == ProblemStatus.closed ||
        status == ProblemStatus.resolved;
    final String label;
    final Color color;

    if (done) {
      label = 'انجام شده';
      color = AppColors.success;
    } else if (status == ProblemStatus.inProgress) {
      label = 'در حال انجام';
      color = AppColors.navyBlue;
    } else {
      label = 'باز';
      color = AppColors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            const Padding(
              padding: EdgeInsets.only(left: 5),
              child: Icon(Icons.check_circle, size: 13, color: AppColors.success),
            ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
