import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../providers/settings_provider.dart';
import '../models/health_item.dart';
import '../utils/theme.dart';
import '../utils/app_l10n.dart';
import '../widgets/toast_overlay.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HealthProvider>().loadItems();
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  void _showPresetPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PresetPickerSheet(),
    );
  }

  void _showItemEditor({HealthItem? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _HealthItemEditor(item: item),
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
            Icon(Icons.favorite, color: AppTheme.healthColor),
            const SizedBox(width: 8),
            Text(l10n.healthTitle),
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
      body: Consumer<HealthProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final l10n2 = AppL10n.of(context);
          if (provider.activeItems.isEmpty) {
            return SlideTransition(
              position: _slideAnimation,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(l10n2.noHealthPlan, style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(l10n2.addHealthHint, style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ),
            );
          }

          return SlideTransition(
            position: _slideAnimation,
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 100),
              itemCount: provider.activeItems.length,
              onReorder: provider.reorderItems,
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) {
                    final double animValue = Curves.easeInOut.transform(animation.value);
                    final elevation = ui.lerpDouble(0, 6, animValue)!;
                    final scale = ui.lerpDouble(1, 1.03, animValue)!;
                    return Transform.scale(
                      scale: scale,
                      child: Material(
                        elevation: elevation,
                        borderRadius: BorderRadius.circular(16),
                        child: child,
                      ),
                    );
                  },
                  child: child,
                );
              },
              itemBuilder: (context, index) {
                final item = provider.activeItems[index];
                return _buildHealthCard(context, item, theme);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemEditor(),
        backgroundColor: AppTheme.healthColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHealthCard(BuildContext context, HealthItem item, ThemeData theme) {
    return Card(
      key: ValueKey(item.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.healthColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getHealthIcon(item.icon),
            color: AppTheme.healthColor,
            size: 24,
          ),
        ),
        title: Text(
          item.name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.defaultValue.isNotEmpty || item.description.isNotEmpty)
              Text(
                item.defaultValue.isNotEmpty ? '建议: ${item.defaultValue}' : item.description,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (item.reminderEnabled)
              Row(
                children: [
                  Icon(Icons.notifications_active, size: 12, color: AppTheme.accentColor),
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

  void _confirmDelete(HealthItem item) {
    final l10n = AppL10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTitle),
        content: Text(l10n.confirmDeleteHealth(item.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              context.read<HealthProvider>().deleteItem(item.id!);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  IconData _getHealthIcon(String iconName) {
    switch (iconName) {
      case 'water_drop': return Icons.water_drop;
      case 'directions_run': return Icons.directions_run;
      case 'visibility': return Icons.visibility;
      case 'self_improvement': return Icons.self_improvement;
      case 'meditation': return Icons.self_improvement;
      case 'bedtime': return Icons.bedtime;
      case 'eco': return Icons.eco;
      case 'directions_walk': return Icons.directions_walk;
      default: return Icons.favorite;
    }
  }
}

// ---- Preset Picker Sheet ----

class _PresetPickerSheet extends StatelessWidget {
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
            child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.presetHealthTitle, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(l10n.presetHealthDesc, style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: l10n.presetHealthItems.length,
              itemBuilder: (context, index) {
                final item = l10n.presetHealthItems[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppTheme.healthColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(_getPresetIcon(item['icon']!), color: AppTheme.healthColor, size: 22),
                  ),
                  title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(item['description']!, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: Icon(Icons.add_circle_outline, color: AppTheme.healthColor),
                    onPressed: () async {
                      final provider = context.read<HealthProvider>();
                      final name = item['name']!;
                      if (provider.hasDuplicateName(name)) {
                        ToastOverlay.show(l10n.duplicateHealth(name));
                        return;
                      }
                      final newItem = HealthItem(
                        name: name, icon: item['icon']!, category: 'preset',
                        description: item['description']!, defaultValue: item['defaultValue'] ?? '',
                        isActive: true, sortOrder: provider.activeItems.length,
                      );
                      await provider.addItem(newItem);
                      if (context.mounted) Navigator.pop(context);
                      ToastOverlay.show(l10n.addedToHealth(name));
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
      case 'water_drop': return Icons.water_drop;
      case 'directions_run': return Icons.directions_run;
      case 'visibility': return Icons.visibility;
      case 'self_improvement': return Icons.self_improvement;
      case 'meditation': return Icons.self_improvement;
      case 'bedtime': return Icons.bedtime;
      case 'eco': return Icons.eco;
      case 'directions_walk': return Icons.directions_walk;
      default: return Icons.favorite;
    }
  }
}

// ---- Health Item Editor ----

class _HealthItemEditor extends StatefulWidget {
  final HealthItem? item;
  const _HealthItemEditor({this.item});

  @override
  State<_HealthItemEditor> createState() => _HealthItemEditorState();
}

class _HealthItemEditorState extends State<_HealthItemEditor> {
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  late TextEditingController _defaultValueCtrl;
  late bool _reminderEnabled;
  late TimeOfDay _reminderTime;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item?.name ?? '');
    _notesCtrl = TextEditingController(text: widget.item?.notes ?? '');
    _defaultValueCtrl = TextEditingController(text: widget.item?.defaultValue ?? '');

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
      return TimeOfDay(hour: int.tryParse(parts[0]) ?? 20, minute: int.tryParse(parts[1]) ?? 0);
    }
    return const TimeOfDay(hour: 20, minute: 0);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    _defaultValueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      helpText: '选择提醒时间',
      cancelText: '取消',
      confirmText: '确认',
    );
    if (picked != null) {
      setState(() => _reminderTime = picked);
    }
  }

  Future<void> _save() async {
    final l10n = AppL10n.of(context);
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ToastOverlay.show(l10n.nameRequired);
      return;
    }

    final provider = context.read<HealthProvider>();

    if (!isEditing && provider.hasDuplicateName(name)) {
      ToastOverlay.show(l10n.duplicateHealth(name));
      return;
    }

    final timeStr = '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}';

    final item = HealthItem(
      id: widget.item?.id,
      name: name,
      icon: widget.item?.icon ?? 'favorite',
      category: widget.item?.category ?? 'custom',
      description: widget.item?.description ?? '',
      defaultValue: _defaultValueCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      reminderEnabled: _reminderEnabled,
      reminderTime: timeStr,
      isActive: widget.item?.isActive ?? true,
      sortOrder: widget.item?.sortOrder ?? 0,
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
    final theme = Theme.of(context);
    final l10n = AppL10n.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            )),
            const SizedBox(height: 20),
            Text(
              isEditing ? l10n.editHealth : l10n.addNewHealth,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: l10n.itemName,
                hintText: l10n.itemNameHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _defaultValueCtrl,
              decoration: InputDecoration(
                labelText: l10n.suggestedValueLabel,
                hintText: l10n.suggestedValueHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.trending_up),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.notesLabel,
                hintText: l10n.notesHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.enableReminder),
              subtitle: _reminderEnabled
                  ? Text(
                      '${l10n.reminderTimeLabel}: ${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: AppTheme.accentColor))
                  : Text(l10n.reminderOffDesc),
              value: _reminderEnabled,
              activeTrackColor: AppTheme.healthColor,
              onChanged: (v) => setState(() => _reminderEnabled = v),
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text('${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  backgroundColor: AppTheme.healthColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(isEditing ? l10n.save : l10n.add, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
