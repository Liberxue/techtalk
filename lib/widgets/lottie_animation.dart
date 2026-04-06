import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLottieAnimation extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final bool repeat;
  final Color? colorOverride;
  final AnimationController? controller;

  const AppLottieAnimation({
    super.key,
    required this.asset,
    this.width = 80,
    this.height = 80,
    this.repeat = true,
    this.colorOverride,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    Widget lottie = Lottie.asset(
      asset,
      width: width,
      height: height,
      repeat: repeat,
      controller: controller,
      errorBuilder: (context, error, stackTrace) {
        return SizedBox(width: width, height: height);
      },
    );

    if (colorOverride != null) {
      lottie = ColorFiltered(
        colorFilter: ColorFilter.mode(
          colorOverride!,
          BlendMode.srcATop,
        ),
        child: lottie,
      );
    }

    return lottie;
  }
}
