import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/overview_provider.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
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
    final currentDate = DateTime.tryParse(provider.currentDate) ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: '选择查看日期',
      cancelText: '取消',
      confirmText: '确认',
    );

    if (picked != null) {
      final dateStr = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      provider.setDate(dateStr);
    }
  }

  @override
  Widget build(BuildContext context) {
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

                  return Text(isToday ? '今日概览' : formatDate(provider.currentDate));
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
            tooltip: '筛选',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              setState(() => _showHistory = !_showHistory);
            },
            tooltip: '历史记录',
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
                  _buildProgressBar(overview, theme),
                  if (_showFilters)
                    FilterBar(
                      categoryFilter: overview.categoryFilter,
                      completionFilter: overview.completionFilter,
                      onCategoryChanged: overview.setCategoryFilter,
                      onCompletionChanged: overview.setCompletionFilter,
                    ),
                  if (_showHistory)
                    _buildHistorySection(theme),
                  if (_showFiltered(overview, 'health'))
                    _buildSectionHeader(
                      icon: Icons.favorite,
                      title: '健康计划',
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
                        onToggle: () => overview.toggleHealthCompletion(h.id!),
                      );
                    }),
                  if (_showFiltered(overview, 'schedule'))
                    _buildSectionHeader(
                      icon: Icons.event,
                      title: '日程安排',
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
                        onToggle: () => overview.toggleScheduleCompletion(s.id!),
                      );
                    }),
                  if (overview.totalTasks == 0)
                    _buildEmptyState(theme),
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

  Widget _buildProgressBar(OverviewProvider overview, ThemeData theme) {
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
                '完成进度',
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              '今天还没有待办事项哦',
              style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[400]),
            ),
            const SizedBox(height: 8),
            Text(
              '去「健康」或「日程」页添加吧~',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getAllHistorySummaries(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text('暂无历史记录', style: TextStyle(color: Colors.grey[400])),
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
                Text('📊 最近一周', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
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
