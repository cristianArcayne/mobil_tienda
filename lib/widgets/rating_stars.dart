import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final int totalResenas;
  final double size;

  const RatingStars({
    super.key,
    required this.rating,
    this.totalResenas = 0,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            if (rating >= starValue) {
              return Icon(Icons.star, color: const Color(0xFFF59E0B), size: size);
            } else if (rating >= starValue - 0.5) {
              return Icon(Icons.star_half, color: const Color(0xFFF59E0B), size: size);
            } else {
              return Icon(Icons.star_border, color: const Color(0xFFCBD5E1), size: size);
            }
          }),
        ),
        if (totalResenas > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($totalResenas)',
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: size - 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

