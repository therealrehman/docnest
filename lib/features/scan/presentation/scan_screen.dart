import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../app/theme/app_spacing.dart';
import '../application/scan_session.dart';
import 'scan_review.dart';

/// Camera screen. Each tap adds a page. With [replacePageId] set, the next photo
/// replaces that page (retake) and the screen closes.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key, this.replacePageId});

  final String? replacePageId;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  CameraController? _controller;
  String? _error;
  bool _capturing = false;

  bool get _isRetake => widget.replacePageId != null;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _setError('No camera was found on this phone.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on Exception {
      _setError(
        'The camera could not start. Check camera permission in phone Settings, then try again.',
      );
    }
  }

  void _setError(String message) {
    if (mounted) setState(() => _error = message);
  }

  void _retry() {
    setState(() => _error = null);
    _startCamera();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _capturing) return;

    setState(() => _capturing = true);
    try {
      final photo = await controller.takePicture();
      final notifier = ref.read(scanSessionProvider.notifier);
      final pageId = widget.replacePageId;
      if (pageId != null) {
        notifier.replacePage(pageId, photo.path);
        _goBack();
        return;
      }
      notifier.addPage(photo.path);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not take the photo. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.documents);
    }
  }

  /// Close button and Android back. Asks before throwing away captured pages.
  Future<void> _close() async {
    if (!_isRetake) {
      final count = ref.read(scanSessionProvider).length;
      if (count > 0) {
        final discard = await confirmDiscardScan(context, count);
        if (!discard || !mounted) return;
        ref.read(scanSessionProvider.notifier).clear();
      }
    }
    if (mounted) _goBack();
  }

  @override
  Widget build(BuildContext context) {
    final pageCount = ref.watch(scanSessionProvider).length;
    final canFinish = !_isRetake && pageCount > 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          title: Text(_isRetake ? 'Retake page' : 'Scan'),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: _close,
          ),
        ),
        body: Column(
          children: [
            Expanded(child: _buildPreview()),
            _buildBottomBar(pageCount, canFinish),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final error = _error;
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DocNestSpacing.screen),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: DocNestSpacing.s),
              TextButton(onPressed: _retry, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: AspectRatio(
        aspectRatio: 1 / controller.value.aspectRatio,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildBottomBar(int pageCount, bool canFinish) {
    final canCapture = _controller?.value.isInitialized == true && !_capturing;
    final label = _isRetake
        ? 'One photo'
        : '$pageCount ${pageCount == 1 ? 'page' : 'pages'}';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DocNestSpacing.screen,
          DocNestSpacing.s,
          DocNestSpacing.screen,
          DocNestSpacing.m,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(label, style: const TextStyle(color: Colors.white70)),
            ),
            Expanded(
              child: Center(
                child: IconButton.filled(
                  tooltip: _isRetake ? 'Take new photo' : 'Take photo',
                  iconSize: 32,
                  onPressed: canCapture ? _capture : null,
                  icon: _capturing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_rounded),
                ),
              ),
            ),
            SizedBox(
              width: 88,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: canFinish ? () => context.push(AppRoutes.scanReview) : null,
                  child: const Text('Done'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
