import 'package:flutter/material.dart';
import 'package:avukatbul/widgets/custom_button.dart';

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  
  const ErrorScreen({
    Key? key,
    this.title = 'Bir Hata Oluştu',
    required this.message,
    this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              if (onRetry != null)
                CustomButton(
                  text: 'Tekrar Dene',
                  onPressed: onRetry!,
                ),
              SizedBox(height: 16),
              CustomButton(
                text: 'Geri Dön',
                onPressed: () => Navigator.pop(context),
                isOutlined: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
