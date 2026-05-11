import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/schedule_provider.dart';
import '../providers/settings_provider.dart';
import '../models/schedule_item.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/app_l10n.dart';
import '../widgets/toast_overlay.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ScheduleProvider>().loadItems();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _showPresetPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _SchedulePresetSheet(),
    );
  }

  void _showItemEditor({ScheduleItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _ScheduleItemEditor(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event, color: AppTheme.scheduleColor),
            const SizedBox(width: 8),
            Text(l10n.scheduleTitle),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _showPresetPicker,
            tooltip: l10n.presetProjectsTooltip,
          ),
        ],
      ),
      body: Consumer<ScheduleProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final l10n2 = AppL10n.of(context);
          if (provider.allItems.isEmpty) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_busy, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      l10n2.noSchedule,
                      style: TextStyle(color: Colors.grey[400], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n2.addScheduleHint,
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group by date
          final grouped = <String, List<ScheduleItem>>{};
          for (final item in provider.allItems) {
            grouped.putIfAbsent(item.scheduleDate, () => []).add(item);
          }

          final sortedDates = grouped.keys.toList()
            ..sort((a, b) => b.compareTo(a)); // Most recent first

          return FadeTransition(
            opacity: _fadeAnimation,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final items = grouped[date]!;

                return _buildDateGroup(date, items, theme);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemEditor(),
        backgroundColor: AppTheme.scheduleColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDateGroup(
    String date,
    List<ScheduleItem> items,
    ThemeData theme,
  ) {
    final isToday = date == todayDate();
    final dateDisplay = isToday ? '今天 ${formatDate(date)}' : formatDate(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppTheme.scheduleColor.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isToday ? Icons.today : Icons.date_range,
                  color: isToday ? AppTheme.scheduleColor : Colors.grey,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateDisplay,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isToday ? AppTheme.scheduleColor : Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        ...items.map((item) => _buildScheduleCard(context, item, theme)),
      ],
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    ScheduleItem item,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.scheduleColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getScheduleIcon(item.icon),
            color: AppTheme.scheduleColor,
            size: 24,
          ),
        ),
        title: Text(
          item.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description.isNotEmpty)
              Text(
                item.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (item.notes.isNotEmpty)
              Text(
                item.notes,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (item.reminderEnabled)
              Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    size: 12,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.reminderTime,
                    style: TextStyle(fontSize: 11, color: AppTheme.accentColor),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showItemEditor(item: item),
              tooltip: '编辑',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _confirmDelete(item),
              tooltip: '删除',
            ),
          ],
        ),
        onTap: () => _showItemEditor(item: item),
      ),
    );
  }

  void _confirmDelete(ScheduleItem item) {
    final l10n = AppL10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteSchedule(item.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              context.read<ScheduleProvider>().deleteItem(item.id!);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getScheduleIcon(String iconName) {
    switch (iconName) {
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
        return Icons.event_note;
    }
  }
}

// ---- Preset Picker ----

class _SchedulePresetSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.presetScheduleTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.presetScheduleDesc,
            style: TextStyle(color: Colors.grey[500]),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: l10n.presetScheduleItems.length,
              itemBuilder: (context, index) {
                final item = l10n.presetScheduleItems[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.scheduleColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getPresetIcon(item['icon']!),
                      color: AppTheme.scheduleColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    item['name']!,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    item['description']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.scheduleColor,
                    ),
                    onPressed: () async {
                      final provider = context.read<ScheduleProvider>();
                      final name = item['name']!;
                      final today = todayDate();
                      if (provider.hasDuplicate(name, today)) {
                        ToastOverlay.show(
                          l10n.duplicateSchedule(name, formatDate(today)),
                          duration: const Duration(seconds: 1),
                        );
                        return;
                      }
                      final newItem = ScheduleItem(
                        name: name,
                        icon: item['icon']!,
                        category: 'preset',
                        description: item['description']!,
                        scheduleDate: today,
                        isActive: true,
                      );
                      await provider.addItem(newItem);
                      if (context.mounted) Navigator.pop(context);
                      ToastOverlay.show(
                        l10n.addedToSchedule(name),
                        duration: const Duration(seconds: 1),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPresetIcon(String iconName) {
    switch (iconName) {
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
        return Icons.event_note;
    }
  }
}

// ---- Schedule Item Editor ----

class _ScheduleItemEditor extends StatefulWidget {
  final ScheduleItem? item;
  const _ScheduleItemEditor({this.item});

  @override
  State<_ScheduleItemEditor> createState() => _ScheduleItemEditorState();
}

class _ScheduleItemEditorState extends State<_ScheduleItemEditor> {
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _descriptionCtrl;
  late DateTime _selectedDate;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _notesCtrl = TextEditingController(text: widget.item?.notes ?? '');
    _descriptionCtrl = TextEditingController(
      text: widget.item?.description ?? '',
    );

    _selectedDate = widget.item != null
        ? DateTime.tryParse(widget.item!.scheduleDate) ?? DateTime.now()
        : DateTime.now();

    final settings = context.read<SettingsProvider>();
    final defaultTime = widget.item != null
        ? _parseTime(widget.item!.reminderTime)
        : _parseTime(settings.defaultReminderTime);

    _reminderEnabled = widget.item?.reminderEnabled ?? false;
    _reminderTime = defaultTime;
  }

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 20,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 20, minute: 0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final l10n = AppL10n.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: l10n.selectDate,
      cancelText: l10n.cancelLabel,
      confirmText: l10n.confirmLabel,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final l10n = AppL10n.of(context);
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: l10n.selectTime,
      cancelText: l10n.cancelLabel,
      confirmText: l10n.confirmLabel,
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _save() async {
    final l10n = AppL10n.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ToastOverlay.show(
        l10n.nameRequired,
        duration: const Duration(seconds: 1),
      );
      return;
    }

    final dateStr =
        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final provider = context.read<ScheduleProvider>();

    if (!isEditing && provider.hasDuplicate(name, dateStr)) {
      final dateDisplay =
          '${_selectedDate.year}.${_selectedDate.month}.${_selectedDate.day}';
      ToastOverlay.show(
        l10n.duplicateSchedule(name, dateDisplay),
        duration: const Duration(seconds: 1),
      );
      return;
    }

    final timeStr =
        '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

    final item = ScheduleItem(
      id: widget.item?.id,
      name: name,
      icon: widget.item?.icon ?? 'event_note',
      category: widget.item?.category ?? 'custom',
      description: _descriptionCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      scheduleDate: dateStr,
      reminderEnabled: _reminderEnabled,
      reminderTime: timeStr,
      isActive: true,
      createdAt: widget.item?.createdAt,
    );

    if (isEditing) {
      await provider.updateItem(item);
    } else {
      await provider.addItem(item);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEditing ? l10n.editSchedule : l10n.addNewSchedule,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.scheduleName,
                hintText: l10n.scheduleNameHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionCtrl,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                hintText: l10n.descriptionHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.notesLabel,
                hintText: l10n.notesHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppTheme.scheduleColor),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.scheduleDateLabel,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedDate.year}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.scheduleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        l10n.changeDate,
                        style: TextStyle(
                          color: AppTheme.scheduleColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.enableReminder),
              subtitle: _reminderEnabled
                  ? Text(
                      '${l10n.reminderTimeLabel}: ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: AppTheme.accentColor),
                    )
                  : Text(l10n.reminderOffDesc),
              value: _reminderEnabled,
              activeTrackColor: AppTheme.scheduleColor,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.scheduleColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEditing ? l10n.save : l10n.add,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
