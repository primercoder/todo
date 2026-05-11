import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class ToastOverlay {
  static OverlayEntry? _entry;

  static void show(
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    _entry?.remove();
    _entry = null;

    final context = NotificationService().navigatorKey.currentContext;
    if (context == null) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        duration: duration,
        onDone: () {
          entry.remove();
          if (_entry == entry) _entry = null;
        },
      ),
    );

    overlay.insert(entry);
    _entry = entry;
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDone;

  const _ToastWidget({
    required this.message,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    Future.delayed(widget.duration - const Duration(milliseconds: 250), () {
      if (mounted) {
        _controller.reverse().then((_) => widget.onDone());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xE5333333),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
