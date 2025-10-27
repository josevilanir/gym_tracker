// lib/features/workout/pages/history/history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/providers.dart';
import 'widgets/quick_filters.dart';
import 'widgets/workout_list_tab.dart';
import 'widgets/stats_tab.dart';
import 'dialogs/register_past_workout_dialog.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> with SingleTickerProviderStateMixin {
  QuickRange _range = QuickRange.last7;
  DateTimeRange? _customRange;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  (DateTime start, DateTime end) _currentBounds() {
    final now = DateTime.now();
    switch (_range) {
      case QuickRange.last7:
        return (now.subtract(const Duration(days: 6)), now);
      case QuickRange.last30:
        return (now.subtract(const Duration(days: 29)), now);
      case QuickRange.thisMonth:
        final repo = ref.read(workoutRepoProvider);
        final b = repo.monthBounds(now);
        return (
          DateTime.fromMillisecondsSinceEpoch(b.startEpoch),
          DateTime.fromMillisecondsSinceEpoch(b.endEpoch),
        );
      case QuickRange.all:
        return (DateTime(2000, 1, 1), now);
      case QuickRange.custom:
        if (_customRange != null) {
          return (_customRange!.start, _customRange!.end);
        }
        return (now.subtract(const Duration(days: 6)), now);
    }
  }

  Future<void> _handleRangeChanged(QuickRange range) async {
    if (range == QuickRange.custom) {
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(DateTime.now().year - 2),
        lastDate: DateTime.now(),
        initialDateRange: _customRange,
      );
      if (picked != null) {
        setState(() {
          _customRange = picked;
          _range = range;
        });
      }
    } else {
      setState(() => _range = range);
    }
  }

  Future<void> _openRegisterDialog() async {
    await showRegisterPastWorkoutDialog(context: context, ref: ref);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Registrar treino retroativo',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _openRegisterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          QuickFilters(current: _range, onSelected: _handleRangeChanged),
          const SizedBox(height: 8),

          if (_tabController != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                tabs: const [
                  Tab(icon: Icon(Icons.list_alt), text: 'Treinos', height: 56),
                  Tab(icon: Icon(Icons.analytics_outlined), text: 'Estatísticas', height: 56),
                ],
              ),
            ),
          const SizedBox(height: 12),

          Expanded(
            child: _tabController != null
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      WorkoutListTab(
                        currentBounds: _currentBounds,
                        onRegisterWorkout: _openRegisterDialog,
                      ),
                      StatsTab(currentBounds: _currentBounds),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}