import 'package:flutter/material.dart';
import '../../core/values/app_values.dart';

/// Feature card widget for displaying app features
class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? iconColor;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.enabled = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? 
        (enabled ? colorScheme.primary : colorScheme.onSurfaceVariant);
    
    return Card(
      elevation: enabled ? 1 : 0,
      color: enabled 
          ? colorScheme.surface 
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppValues.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppValues.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: AppValues.iconSizeLarge,
                color: effectiveIconColor,
              ),
              const SizedBox(height: AppValues.paddingSmall),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: enabled 
                      ? colorScheme.onSurface 
                      : colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled 
                      ? colorScheme.onSurfaceVariant 
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!enabled) ...[
                const SizedBox(height: AppValues.paddingSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppValues.paddingSmall,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppValues.radiusSmall),
                  ),
                  child: Text(
                    'Requires Sign In',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}