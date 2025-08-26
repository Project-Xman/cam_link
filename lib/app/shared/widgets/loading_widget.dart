import 'package:flutter/material.dart';
import '../../core/values/app_values.dart';

/// Loading widget with customizable message
class LoadingWidget extends StatelessWidget {
  final String? message;
  final bool showProgress;
  final double? progress;

  const LoadingWidget({
    super.key,
    this.message,
    this.showProgress = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(AppValues.paddingLarge),
        child: Padding(
          padding: const EdgeInsets.all(AppValues.paddingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showProgress && progress != null)
                CircularProgressIndicator(value: progress)
              else
                const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: AppValues.paddingMedium),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}