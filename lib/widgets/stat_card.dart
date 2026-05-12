// lib/widgets/stat_card.dart

import 'package:flutter/material.dart';

/// A reusable summary card that displays a [title], a [value], and an [icon].
///
/// Used on the Dashboard to show key metrics at a glance.
class StatCard extends StatelessWidget {
  /// The label displayed above the value (e.g. "Total Mentors").
  final String title;

  /// The primary value displayed in large text (e.g. "42" or "31 Dec 2026").
  final String value;

  /// The icon displayed alongside the title.
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      shadowColor: colorScheme.shadow.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Icon container.
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 24.0),
            ),
            const SizedBox(width: 16.0),
            // Title and value.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    value,
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
