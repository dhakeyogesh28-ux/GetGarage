import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Widget icon;
  final MetricTrend? trend;
  final MetricVariant variant;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    this.trend,
    this.variant = MetricVariant.defaultVariant,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        gradient: _getGradient(),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mutedForeground,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.mutedForeground,
                          ),
                    ),
                  ],
                ],
              ),
              if (trend != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      trend!.positive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: trend!.positive ? AppColors.success : AppColors.destructive,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${trend!.value}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: trend!.positive ? AppColors.success : AppColors.destructive,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Text(
                        'vs last week',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _getIconBgColor(),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconTheme(
                data: IconThemeData(
                  color: _getIconColor(),
                  size: 20,
                ),
                child: icon,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0, duration: 300.ms);
  }

  LinearGradient _getGradient() {
    switch (variant) {
      case MetricVariant.primary:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)],
        );
      case MetricVariant.success:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.success.withOpacity(0.15), AppColors.success.withOpacity(0.05)],
        );
      case MetricVariant.warning:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.warning.withOpacity(0.15), AppColors.warning.withOpacity(0.05)],
        );
      case MetricVariant.info:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.info.withOpacity(0.15), AppColors.info.withOpacity(0.05)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF242930), Color(0xFF1A1E24)],
        );
    }
  }

  Color _getIconBgColor() {
    switch (variant) {
      case MetricVariant.primary:
        return AppColors.primary.withOpacity(0.15);
      case MetricVariant.success:
        return AppColors.success.withOpacity(0.15);
      case MetricVariant.warning:
        return AppColors.warning.withOpacity(0.15);
      case MetricVariant.info:
        return AppColors.info.withOpacity(0.15);
      default:
        return AppColors.secondary;
    }
  }

  Color _getIconColor() {
    switch (variant) {
      case MetricVariant.primary:
        return AppColors.primary;
      case MetricVariant.success:
        return AppColors.success;
      case MetricVariant.warning:
        return AppColors.warning;
      case MetricVariant.info:
        return AppColors.info;
      default:
        return AppColors.foreground;
    }
  }
}

enum MetricVariant { defaultVariant, primary, success, warning, info }

class MetricTrend {
  final double value;
  final bool positive;

  const MetricTrend(this.value, this.positive);
}
