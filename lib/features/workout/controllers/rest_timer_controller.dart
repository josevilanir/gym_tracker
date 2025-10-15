import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

@immutable
class RestTimerState {
  final bool running;
  final int total;      // segundos
  final int remaining;  // segundos

  const RestTimerState({
    required this.running,
    required this.total,
    required this.remaining,
  });

  const RestTimerState.idle() : this(running: false, total: 0, remaining: 0);

  String get label {
    final m = (remaining ~/ 60).toString().padLeft(2, '0');
    final s = (remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get progress =>
      total == 0 ? 0 : (total - remaining).clamp(0, total) / total;
}

class RestTimerController extends StateNotifier<RestTimerState> {
  RestTimerController() : super(const RestTimerState.idle());

  Timer? _ticker;

  void start(int seconds) {
    _ticker?.cancel();
    if (seconds <= 0) {
      state = const RestTimerState.idle();
      return;
    }
    state = RestTimerState(running: true, total: seconds, remaining: seconds);

    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.remaining - 1;
      if (left <= 0) {
        t.cancel();
        state = const RestTimerState.idle();
        _notifyEnd();
      } else {
        state = RestTimerState(running: true, total: state.total, remaining: left);
      }
    });
  }

  void pause() {
    _ticker?.cancel();
    if (state.running) {
      state = RestTimerState(running: false, total: state.total, remaining: state.remaining);
    }
  }

  void resume() {
    if (state.remaining <= 0 || state.running) return;
    start(state.remaining);
  }

  void stop() {
    _ticker?.cancel();
    state = const RestTimerState.idle();
  }

  Future<void> _notifyEnd() async {
  try {
    final player = FlutterRingtonePlayer();
    await player.playNotification(
      // opcionais:
      asAlarm: false,
      looping: false,
      // volume: 0.9, // se quiser
    );
  } catch (_) {
    // ignora falhas ao tentar tocar o som
  }
}

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final restTimerProvider =
    StateNotifierProvider<RestTimerController, RestTimerState>(
  (ref) => RestTimerController(),
);
