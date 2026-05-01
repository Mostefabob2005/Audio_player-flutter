// lib/presentation/widgets/player/seek_bar.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration bufferedPosition;
  final ValueChanged<Duration>? onChanged;

  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    this.onChanged,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.duration.inMilliseconds.toDouble();
    final value = min(_dragValue ?? widget.position.inMilliseconds.toDouble(), max);

    return Column(
      children: [
        Slider(
          min: 0,
          max: max > 0 ? max : 1,
          value: value.clamp(0, max > 0 ? max : 1),
          onChanged: (v) => setState(() => _dragValue = v),
          onChangeEnd: (v) {
            widget.onChanged?.call(Duration(milliseconds: v.round()));
            setState(() => _dragValue = null);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _format(Duration(milliseconds: value.round())),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
              Text(
                _format(widget.duration),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
