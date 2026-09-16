import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;
  final Function(double)? onRatingChanged;
  
  const RatingBar({
    Key? key,
    required this.rating,
    this.size = 24,
    this.color = Colors.amber,
    this.onRatingChanged,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: onRatingChanged != null ? () => onRatingChanged!(index + 1) : null,
          child: Icon(
            index < rating.floor()
              ? Icons.star
              : index < rating
                ? Icons.star_half
                : Icons.star_border,
            color: color,
            size: size,
          ),
        );
      }),
    );
  }
}
