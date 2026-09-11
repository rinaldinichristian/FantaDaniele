import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'bug_reporter_modal.dart';

class ShakeDetectorWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const ShakeDetectorWrapper({super.key, required this.child});

  @override
  ConsumerState<ShakeDetectorWrapper> createState() =>
      _ShakeDetectorWrapperState();
}

class _ShakeDetectorWrapperState extends ConsumerState<ShakeDetectorWrapper> {
  final ScreenshotController _screenshotController = ScreenshotController();
  StreamSubscription<AccelerometerEvent>? _streamSubscription;
  DateTime _lastShake = DateTime.now();
  bool _isReporting = false;

  @override
  void initState() {
    super.initState();
    _streamSubscription = accelerometerEventStream().listen((
      AccelerometerEvent event,
    ) {
      if (_isReporting) return;

      // Calculate shake magnitude
      double gX = event.x / 9.80665;
      double gY = event.y / 9.80665;
      double gZ = event.z / 9.80665;
      double gForce = sqrt(gX * gX + gY * gY + gZ * gZ);

      // Threshold for shake (e.g., 2.5 g)
      if (gForce > 2.5) {
        final now = DateTime.now();
        if (now.difference(_lastShake) > const Duration(seconds: 2)) {
          _lastShake = now;
          _handleShake();
        }
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _handleShake() async {
    setState(() => _isReporting = true);
    try {
      // Capture screenshot
      final screenshot = await _screenshotController.capture();

      if (!mounted) return;

      final navContext = context;
      if (!navContext.mounted) return;

      await showModalBottomSheet(
        context: navContext,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) => BugReporterModal(
          screenshotBytes: screenshot,
          locationContext: 'FantaDaniele',
        ),
      );
    } catch (e) {
      debugPrint('Error handling shake: $e');
    } finally {
      if (mounted) setState(() => _isReporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: _screenshotController,
      child: widget.child,
    );
  }
}
