
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(BuildContext, FlutterErrorDetails)? fallbackBuilder;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallbackBuilder,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _error;

  @override
  void initState() {
    super.initState();
    // In strict error boundary mode, this might catch some errors if structured correctly,
    // but Flutter's build phase errors are usually caught by the framework.
    // This widget is useful if we manually catch and setState. 
    // However, since Flutter 3.x, standard ErrorWidget.builder is preferred for UI build crashes.
  }

  // To truly catch errors in children without crashing the app, 
  // we often rely on standard generic exception handling in async methods.
  // For Rebuild errors, Flutter calls ErrorWidget.builder.
  
  // This widget serves as a semantic wrapper for where we MIGHT introduce `ErrorWidget` override scoping.
  // But purely as a stateful widget, it can't catch render exceptions of children automatically 
  // unless we use `ErrorWidget.builder` globally or Zone guarding.
  
  @override
  Widget build(BuildContext context) {
    // If we were implementing a functional boundary via builder override:
    if (_error != null) {
      return widget.fallbackBuilder?.call(context, _error!) ?? 
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 48),
              const SizedBox(height: 16),
              const Text("Something went wrong.", style: TextStyle(color: Colors.white)),
              TextButton(
                onPressed: () => setState(() => _error = null), 
                child: const Text("Retry")
              )
            ],
          ),
        );
    }
    return widget.child;
  }
}

// Global Error Builder implementation
Widget globalErrorBuilder(FlutterErrorDetails details) {
  return Scaffold(
    backgroundColor: const Color(0xFF1E1E1E),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bug_report, color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            const Text(
              "Inhaus Brain encountered an error.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              details.exception.toString().split('\n').first,
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // In a real app we might try to navigate home or restart
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Reload Interface"),
            )
          ],
        ),
      ),
    ),
  );
}
