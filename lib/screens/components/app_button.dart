import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AppButtonType { primary, emerald, secondary, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final IconData? icon;
  final bool isFullWidth;
  final bool isLoading;
  final double height;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.icon,
    this.isFullWidth = false,
    this.isLoading = false,
    this.height = 42,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final _ButtonStyleConfig config = _getStyleConfig();

    final Widget buttonChild = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: config.foregroundColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: config.iconColor ?? config.foregroundColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: config.foregroundColor,
                ),
              ),
            ],
          );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: config.backgroundColor,
          foregroundColor: config.foregroundColor,
          disabledBackgroundColor: AppColors.surfaceMuted,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: config.borderSide ?? BorderSide.none,
          ),
        ),
        child: buttonChild,
      ),
    );
  }

  _ButtonStyleConfig _getStyleConfig() {
    switch (type) {
      case AppButtonType.primary:
        return _ButtonStyleConfig(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          iconColor: AppColors.accentMint,
        );
      case AppButtonType.emerald:
        return _ButtonStyleConfig(
          backgroundColor: const Color(0xFF059669), // emerald-600
          foregroundColor: Colors.white,
        );
      case AppButtonType.secondary:
        return _ButtonStyleConfig(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          borderSide: const BorderSide(color: AppColors.border),
        );
      case AppButtonType.danger:
        return _ButtonStyleConfig(
          backgroundColor: AppColors.dangerBg,
          foregroundColor: AppColors.dangerText,
        );
    }
  }
}

class _ButtonStyleConfig {
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? iconColor;
  final BorderSide? borderSide;

  _ButtonStyleConfig({
    required this.backgroundColor,
    required this.foregroundColor,
    this.iconColor,
    this.borderSide,
  });
}
