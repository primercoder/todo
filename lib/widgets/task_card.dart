import 'package:flutter/material.dart';
import '../utils/theme.dart';

class TaskCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String icon;
  final bool isCompleted;
  final VoidCallback onToggle;
  final VoidCallback onTapDetail;
  final bool isHealth;
  final String? notes;
  final String? description;
  final String? defaultValue;
  final String? category;

  const TaskCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.onToggle,
    required this.onTapDetail,
    this.isHealth = true,
    this.notes,
    this.description,
    this.defaultValue,
    this.category,
  });

  IconData _getIcon() {
    switch (icon) {
      case 'water_drop':
        return Icons.water_drop;
      case 'directions_run':
        return Icons.directions_run;
      case 'visibility':
        return Icons.visibility;
      case 'self_improvement':
        return Icons.self_improvement;
      case 'meditation':
        return Icons.self_improvement;
      case 'bedtime':
        return Icons.bedtime;
      case 'eco':
        return Icons.eco;
      case 'directions_walk':
        return Icons.directions_walk;
      case 'menu_book':
        return Icons.menu_book;
      case 'spellcheck':
        return Icons.spellcheck;
      case 'edit_note':
        return Icons.edit_note;
      case 'assignment':
        return Icons.assignment;
      case 'replay':
        return Icons.replay;
      case 'code':
        return Icons.code;
      case 'biotech':
        return Icons.biotech;
      case 'lightbulb':
        return Icons.lightbulb;
      default:
        return isHealth ? Icons.favorite : Icons.event;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Card(
        color: isCompleted
            ? AppTheme.completedColor.withValues(alpha: 0.15)
            : null,
        child: InkWell(
          onTap: onTapDetail,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.completedColor
                        : (isHealth
                              ? AppTheme.healthColor
                              : AppTheme.scheduleColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: Icon(_getIcon(), color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: isCompleted ? Colors.grey : null,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (notes != null && notes!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggle,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey(isCompleted),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppTheme.completedColor
                              : Colors.transparent,
                          border: isCompleted
                              ? null
                              : Border.all(color: Colors.grey[400]!, width: 2),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
