import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback? onPressed;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.height = 53,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                text,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
      ),
    );
  }
}
