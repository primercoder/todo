import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/overview_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/app_l10n.dart';
import '../widgets/task_card.dart';
import '../widgets/filter_bar.dart';
import '../database/database_helper.dart';

class OverviewPage extends StatefulWidget {
  const OverviewPage({super.key});

  @override
  State<OverviewPage> createState() => _OverviewPageState();
}

class _OverviewPageState extends State<OverviewPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showFilters = false;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OverviewProvider>().initializeToday();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final provider = context.read<OverviewProvider>();
    final l10n = AppL10n.of(context);
    final currentDate = DateTime.tryParse(provider.currentDate) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: l10n.selectDate,
      cancelText: l10n.cancelLabel,
      confirmText: l10n.confirmLabel,
    );

    if (picked != null) {
      final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      provider.setDate(dateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _selectDate,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_today, size: 18),
              const SizedBox(width: 8),
              Consumer<OverviewProvider>(
                builder: (context, provider, _) {
                  final date = DateTime.tryParse(provider.currentDate);
                  final today = DateTime.now();
                  final isToday = date != null &&
                      date.year == today.year &&
                      date.month == today.month &&
                      date.day == today.day;

                  return Text(isToday ? l10n.todayOverview : formatDate(provider.currentDate));
                },
              ),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
            tooltip: l10n.filter,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              setState(() => _showHistory = !_showHistory);
            },
            tooltip: l10n.historyLabel,
          ),
        ],
      ),
      body: Consumer<OverviewProvider>(
        builder: (context, overview, child) {
          if (overview.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return FadeTransition(
            opacity: _fadeAnimation,
            child: RefreshIndicator(
              onRefresh: () => overview.loadData(),
              child: ListView(
                children: [
                  _buildProgressBar(overview, theme, l10n),
                  if (_showFilters)
                    FilterBar(
                      categoryFilter: overview.categoryFilter,
                      completionFilter: overview.completionFilter,
                      onCategoryChanged: overview.setCategoryFilter,
                      onCompletionChanged: overview.setCompletionFilter,
                      categoryLabel: l10n.category,
                      completionLabel: l10n.completion,
                      allLabel: l10n.all,
                      healthLabel: l10n.health,
                      scheduleLabel: l10n.schedule,
                      completedLabel: l10n.completed,
                      incompleteLabel: l10n.incomplete,
                    ),
                  if (_showHistory)
                    _buildHistorySection(theme, l10n),
                  if (_showFiltered(overview, 'health'))
                    _buildSectionHeader(
                      icon: Icons.favorite,
                      title: l10n.healthPlan,
                      color: AppTheme.healthColor,
                    ),
                  if (_showFiltered(overview, 'health'))
                    ...overview.filteredHealthItems.map((h) {
                      final completed = overview.healthCompletion[h.id] ?? false;
                      return TaskCard(
                        title: h.name,
                        subtitle: h.defaultValue.isNotEmpty ? '建议: ${h.defaultValue}' : h.description,
                        icon: h.icon,
                        isCompleted: completed,
                        isHealth: true,
                        notes: h.notes.isNotEmpty ? h.notes : null,
                        description: h.description.isNotEmpty ? h.description : null,
                        defaultValue: h.defaultValue.isNotEmpty ? h.defaultValue : null,
                        category: h.category,
                        onToggle: () => overview.toggleHealthCompletion(h.id!),
                        onTapDetail: () => _showDetailSheet(
                          context,
                          name: h.name,
                          icon: h.icon,
                          isHealth: true,
                          description: h.description,
                          defaultValue: h.defaultValue,
                          notes: h.notes,
                          category: h.category,
                          reminderTime: h.reminderEnabled ? h.reminderTime : null,
                          isCompleted: completed,
                        ),
                      );
                    }),
                  if (_showFiltered(overview, 'schedule'))
                    _buildSectionHeader(
                      icon: Icons.event,
                      title: l10n.schedulePlan,
                      color: AppTheme.scheduleColor,
                    ),
                  if (_showFiltered(overview, 'schedule'))
                    ...overview.filteredScheduleItems.map((s) {
                      final completed = overview.scheduleCompletion[s.id] ?? false;
                      return TaskCard(
                        title: s.name,
                        subtitle: s.description.isNotEmpty ? s.description : null,
                        icon: s.icon,
                        isCompleted: completed,
                        isHealth: false,
                        notes: s.notes.isNotEmpty ? s.notes : null,
                        description: s.description.isNotEmpty ? s.description : null,
                        category: s.category,
                        onToggle: () => overview.toggleScheduleCompletion(s.id!),
                        onTapDetail: () => _showDetailSheet(
                          context,
                          name: s.name,
                          icon: s.icon,
                          isHealth: false,
                          description: s.description,
                          notes: s.notes,
                          category: s.category,
                          scheduleDate: s.scheduleDate,
                          reminderTime: s.reminderEnabled ? s.reminderTime : null,
                          isCompleted: completed,
                        ),
                      );
                    }),
                  if (overview.totalTasks == 0)
                    _buildEmptyState(theme, l10n),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _showFiltered(OverviewProvider overview, String type) {
    if (overview.categoryFilter == 'all') return true;
    return overview.categoryFilter == type;
  }

  Widget _buildProgressBar(OverviewProvider overview, ThemeData theme, AppL10n l10n) {
    final rate = overview.completionRate;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.8),
            AppTheme.secondaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.completionProgress,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${overview.completedTasks}/${overview.totalTasks}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 12,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 1.0
                    ? AppTheme.completedColor
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(rate * 100).toInt()}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title, required Color color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailSheet(
    BuildContext context, {
    required String name,
    required String icon,
    required bool isHealth,
    String? description,
    String? defaultValue,
    String? notes,
    String? category,
    String? scheduleDate,
    String? reminderTime,
    required bool isCompleted,
  }) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isHealth ? AppTheme.healthColor : AppTheme.scheduleColor).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_detailIcon(icon), color: isHealth ? AppTheme.healthColor : AppTheme.scheduleColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                      if (category != null && category != 'custom')
                        Text(
                          category == 'preset' ? l10n.presetLabel : category,
                          style: TextStyle(color: isHealth ? AppTheme.healthColor : AppTheme.scheduleColor, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppTheme.completedColor : Colors.transparent,
                    border: isCompleted ? null : Border.all(color: Colors.grey[400]!, width: 2),
                  ),
                  child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 22) : null,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (description != null && description.isNotEmpty) ...[
              _buildDetailRow(context, Icons.info_outline, l10n.descriptionLabel, description),
              const SizedBox(height: 12),
            ],
            if (defaultValue != null && defaultValue.isNotEmpty) ...[
              _buildDetailRow(context, Icons.trending_up, l10n.suggestedValueLabel, defaultValue),
              const SizedBox(height: 12),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              _buildDetailRow(context, Icons.note, l10n.notesLabel, notes),
              const SizedBox(height: 12),
            ],
            if (scheduleDate != null && scheduleDate.isNotEmpty) ...[
              _buildDetailRow(context, Icons.calendar_today, l10n.scheduleDateLabel, formatDate(scheduleDate)),
              const SizedBox(height: 12),
            ],
            if (reminderTime != null) ...[
              _buildDetailRow(context, Icons.notifications_active, l10n.reminderTimeLabel, '每天 $reminderTime'),
              const SizedBox(height: 12),
            ],
            _buildDetailRow(
              context,
              isCompleted ? Icons.check_circle : Icons.circle_outlined,
              l10n.statusLabel,
              isCompleted ? l10n.completedStatus : l10n.incompleteStatus,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[500]),
        const SizedBox(width: 10),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  IconData _detailIcon(String iconName) {
    switch (iconName) {
      case 'water_drop': return Icons.water_drop;
      case 'directions_run': return Icons.directions_run;
      case 'visibility': return Icons.visibility;
      case 'self_improvement': return Icons.self_improvement;
      case 'bedtime': return Icons.bedtime;
      case 'eco': return Icons.eco;
      case 'directions_walk': return Icons.directions_walk;
      case 'menu_book': return Icons.menu_book;
      case 'spellcheck': return Icons.spellcheck;
      case 'edit_note': return Icons.edit_note;
      case 'assignment': return Icons.assignment;
      case 'replay': return Icons.replay;
      case 'code': return Icons.code;
      case 'biotech': return Icons.biotech;
      case 'lightbulb': return Icons.lightbulb;
      default: return Icons.favorite;
    }
  }

  Widget _buildEmptyState(ThemeData theme, AppL10n l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(l10n.noTasks, style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[400])),
            const SizedBox(height: 8),
            Text(l10n.addFromTabs, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(ThemeData theme, AppL10n l10n) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getAllHistorySummaries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(l10n.noHistory, style: TextStyle(color: Colors.grey[400])),
              ),
            ),
          );
        }

        final summaries = snapshot.data!.take(7).toList();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.recentWeek, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...summaries.map((s) {
                  final date = s['date'] as String;
                  final completed = s['completed_count'] as int? ?? 0;
                  final total = s['total_count'] as int? ?? 0;
                  final rate = total > 0 ? completed / total : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            formatDate(date),
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                          ),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: rate,
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rate >= 1.0 ? AppTheme.completedColor : AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(rate * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
