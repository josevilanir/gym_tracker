// lib/features/workout/pages/widgets/rest_timer_bar.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/rest_timer_controller.dart';
import '../../../../core/constants.dart';

/// Barra fixa na parte inferior com controles do timer de descanso
/// 
/// Mostra botões rápidos quando o timer está parado
/// e controles de play/pause/stop quando está rodando
class RestTimerBar extends ConsumerWidget {
  const RestTimerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(restTimerProvider);
    final controller = ref.read(restTimerProvider.notifier);

    final isVisible = state.running || state.remaining > 0;

    if (!isVisible) {
      return _QuickTimerButtons(onStart: controller.start);
    }

    return _ActiveTimerBar(
      state: state,
      onPause: controller.pause,
      onResume: controller.resume,
      onStop: controller.stop,
    );
  }
}

/// Botões rápidos para iniciar timer com valores predefinidos
class _QuickTimerButtons extends StatelessWidget {
  final void Function(int) onStart;

  const _QuickTimerButtons({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: PaddingConstants.horizontalM.copyWith(
          bottom: UIConstants.paddingS,
        ),
        child: Row(
          children: [
            const Text('Descanso rápido:'),
            SizedBox(width: UIConstants.paddingS),
            for (final seconds in AppConstants.restTimerQuickOptions)
              Padding(
                padding: EdgeInsets.only(right: UIConstants.paddingS),
                child: OutlinedButton(
                  onPressed: () => onStart(seconds),
                  child: Text('${seconds}s'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Barra com controles do timer ativo
class _ActiveTimerBar extends StatelessWidget {
  final RestTimerState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  const _ActiveTimerBar({
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: PaddingConstants.horizontalM.copyWith(
          bottom: UIConstants.paddingS,
        ),
        padding: PaddingConstants.horizontalM.copyWith(
          top: UIConstants.paddingS,
          bottom: UIConstants.paddingS,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(UIConstants.radiusM),
          boxShadow: const [
            BoxShadow(blurRadius: 6, color: Colors.black12),
          ],
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(
              width: 60,
              child: Text(
                state.label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: PaddingConstants.horizontalM,
                child: LinearProgressIndicator(
                  value: state.progress,
                  minHeight: 4,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.running)
                  IconButton(
                    icon: const Icon(Icons.pause),
                    onPressed: onPause,
                  )
                else if (state.remaining > 0)
                  IconButton(
                    icon: const Icon(Icons.play_arrow),
                    onPressed: onResume,
                  ),
                IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: onStop,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}