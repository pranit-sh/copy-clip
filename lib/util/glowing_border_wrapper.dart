import 'package:flutter/material.dart';

class GlowingBorderWrapper extends StatefulWidget {
  final bool isLoading;
  final Widget child;

  const GlowingBorderWrapper({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  State<GlowingBorderWrapper> createState() => _GlowingBorderWrapperState();
}

class _GlowingBorderWrapperState extends State<GlowingBorderWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(); // Loop the animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned.fill(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return LinearGradient(
                    colors: [Colors.yellow, Colors.blue, Colors.red],
                    stops: const [0.0, 0.5, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    transform:
                        GradientRotation(_controller.value * 2 * 3.1416),
                  ).createShader(rect);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(width: 2, color: Colors.white),
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
