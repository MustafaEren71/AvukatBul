import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutlined;
  final IconData? icon;
  
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isOutlined = false,
    this.icon,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (icon != null) {
      return isOutlined
        ? OutlinedButton.icon(
            icon: Icon(icon),
            label: Text(text),
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        : ElevatedButton.icon(
            icon: Icon(icon),
            label: Text(text),
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
    } else {
      return isOutlined
        ? OutlinedButton(
            child: Text(text),
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          )
        : ElevatedButton(
            child: Text(text),
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
    }
  }
}
