import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading._({
    required this.width,
    required this.height,
    this.shapeBorder = const RoundedRectangleBorder(),
  });

  const ShimmerLoading.circular({
    required double size,
  }) : this._(width: size, height: size, shapeBorder: const CircleBorder());

  const ShimmerLoading.rectangular({
    required double width,
    required double height,
  }) : this._(
          width: width,
          height: height,
          shapeBorder: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: ShapeDecoration(
          color: Colors.grey[300]!,
          shape: shapeBorder,
        ),
      ),
    );
  }
}
