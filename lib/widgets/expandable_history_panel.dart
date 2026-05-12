// lib/widgets/expandable_history_panel.dart

import 'package:flutter/material.dart';

import '../models/institution_model.dart';
import '../utils/date_formatter.dart';
import '../utils/error_messages.dart';

/// An expandable panel that displays an institution's subscription history.
///
/// Collapsed by default. When expanded, shows one row per
/// [SubscriptionHistoryEntry] sorted by [SubscriptionHistoryEntry.startDate]
/// descending (most recent first).
///
/// Each row shows:
/// - Start date (dd MMM yyyy)
/// - End date (dd MMM yyyy)
/// - Duration in whole days (e.g. "30 days")
/// - A status chip: green "Active" or grey "Expired"
///
/// If [entries] is empty, displays [SubscriptionMessages.noSubscriptionHistory].
class ExpandableHistoryPanel extends StatelessWidget {
  /// The list of subscription history entries to display.
  final List<SubscriptionHistoryEntry> entries;

  const ExpandableHistoryPanel({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    // Sort entries by startDate descending (most recent first).
    final sorted = List<SubscriptionHistoryEntry>.from(entries)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    return ExpansionTile(
      title: const Text('Subscription History'),
      initiallyExpanded: false,
      children: [
        if (sorted.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.75),
                  style: BorderStyle.solid,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 28.0,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.history,
                      size: 44,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      SubscriptionMessages.noSubscriptionHistory,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      SubscriptionMessages.noSubscriptionHistoryHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Start Date')),
                DataColumn(label: Text('End Date')),
                DataColumn(label: Text('Duration')),
                DataColumn(label: Text('Status')),
              ],
              rows: sorted.map((entry) => _buildRow(context, entry)).toList(),
            ),
          ),
      ],
    );
  }

  DataRow _buildRow(BuildContext context, SubscriptionHistoryEntry entry) {
    final startText = formatSubscriptionDate(entry.startDate);
    final endText = formatSubscriptionDate(entry.endDate);
    final durationText = '${entry.durationDays} days';
    final isActive = entry.status == SubscriptionStatus.active;

    return DataRow(
      cells: [
        DataCell(Text(startText)),
        DataCell(Text(endText)),
        DataCell(Text(durationText)),
        DataCell(_StatusChip(isActive: isActive)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _StatusChip — internal chip widget for Active / Expired status
// ---------------------------------------------------------------------------

class _StatusChip extends StatelessWidget {
  final bool isActive;

  const _StatusChip({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        isActive ? StatusLabels.active : StatusLabels.expired,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.black87,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: isActive ? Colors.green.shade600 : Colors.grey.shade400,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }
}
