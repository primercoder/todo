import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final String categoryFilter;
  final String completionFilter;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onCompletionChanged;

  const FilterBar({
    super.key,
    required this.categoryFilter,
    required this.completionFilter,
    required this.onCategoryChanged,
    required this.onCompletionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('类别', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildChip(context, '全部', 'all', categoryFilter, onCategoryChanged),
                const SizedBox(width: 8),
                _buildChip(context, '健康', 'health', categoryFilter, onCategoryChanged),
                const SizedBox(width: 8),
                _buildChip(context, '日程', 'schedule', categoryFilter, onCategoryChanged),
              ],
            ),
            const SizedBox(height: 10),
            Text('完成度', style: theme.textTheme.labelMedium?.copyWith(color: Colors.grey)),
            const SizedBox(height: 6),
            Row(
              children: [
                _buildChip(context, '全部', 'all', completionFilter, onCompletionChanged),
                const SizedBox(width: 8),
                _buildChip(context, '已完成', 'completed', completionFilter, onCompletionChanged),
                const SizedBox(width: 8),
                _buildChip(context, '未完成', 'incomplete', completionFilter, onCompletionChanged),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, String value, String current, ValueChanged<String> onChange) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => onChange(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
