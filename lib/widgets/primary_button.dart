import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool isLoading;
  final bool isSecondary;

  const PrimaryButton({
    super.key,
    required this.onTap,
    required this.label,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56, // Match the height from the mockup
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? Colors.white : Colors.black,
          foregroundColor: isSecondary ? Colors.black : Colors.white,
          disabledBackgroundColor:
              (isSecondary ? Colors.white : Colors.black).withValues(alpha: 0.35),
          disabledForegroundColor: Colors.white54,
          elevation: isSecondary ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: (isLoading || onTap == null) ? null : onTap,
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isSecondary ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
      ),
    );
  }
}
