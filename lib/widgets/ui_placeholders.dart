import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.surfaceSoft,
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class LoadingPlaceholderCard extends StatelessWidget {
  const LoadingPlaceholderCard({super.key, this.rows = 3});

  final int rows;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          for (var i = 0; i < rows; i++) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: i == 0 ? .78 : .55,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            if (i != rows - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
