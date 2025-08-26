import 'package:flutter/material.dart';
import '../../core/values/app_values.dart';

/// Status card widget for displaying system status
class StatusCard extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;
  final bool isPositive;
  final VoidCallback? onTap;

  const StatusCard({
    super.key,
    required this.title,
    required this.status,
    required this.icon,
    this.isPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final statusColor = isPositive ? colorScheme.primary : colorScheme.error;
    final backgroundColor = isPositive 
        ? colorScheme.primaryContainer 
        : colorScheme.errorContainer;
    final onBackgroundColor = isPositive 
        ? colorScheme.onPrimaryContainer 
        : colorScheme.onErrorContainer;

    return Card(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppValues.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppValues.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: statusColor,
                    size: AppValues.iconSizeMedium,
                  ),
                  const SizedBox(width: AppValues.paddingSmall),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: onBackgroundColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppValues.paddingSmall),
              Text(
                status,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}