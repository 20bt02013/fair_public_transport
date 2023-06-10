import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedTextLoop extends StatefulWidget {
  const AnimatedTextLoop({Key? key}) : super(key: key);

  @override
  State<AnimatedTextLoop> createState() => _AnimatedTextLoopState();
}

class _AnimatedTextLoopState extends State<AnimatedTextLoop>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3), // Adjust the duration as needed
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(seconds: 3), // Adjust the duration as needed
      left: _animationController.value * MediaQuery.of(context).size.width,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(seconds: 3), // Adjust the duration as needed
        builder: (BuildContext context, double value, Widget? child) {
          return Opacity(
            opacity: value,
            child: child,
          );
        },
        child: Text(
          'Providing best services',
          style: GoogleFonts.blinker(
            textStyle: const TextStyle(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              letterSpacing: .5,
            ),
          ),
        ),
      ),
    );
  }
}
