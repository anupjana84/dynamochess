import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  const BackgroundWidget({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: double.infinity,
          width: double.infinity,
          color: const Color(0xFF1d0041), //Color(0xFF4E3D9C),
          child: Center(
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset(
                "assets/images/background.png",
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
        child
      ],
    );
  }
}
