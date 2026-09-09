import 'package:flutter/material.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';

enum ZipBizButtonType { primary, secondary, outline, text }

class ZipBizButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ZipBizButtonType type;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final double borderRadius;

  const ZipBizButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ZipBizButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    if (type == ZipBizButtonType.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        child: Text(
          text,
          style: ZipBizTypography.labelLarge.copyWith(
            color: ZipBizColors.primaryContainer,
          ),
        ),
      );
    }

    if (type == ZipBizButtonType.outline) {
      return SizedBox(
        width: width,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: ZipBizColors.primaryContainer, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: _buildChild(ZipBizColors.primaryContainer),
        ),
      );
    }

    final isSecondary = (type == ZipBizButtonType.secondary);
    final bgColor = isSecondary ? ZipBizColors.secondary : ZipBizColors.primaryContainer;
    final fgColor = isSecondary ? ZipBizColors.onSecondary : ZipBizColors.onPrimary;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _buildChild(fgColor),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: ZipBizTypography.labelLarge.copyWith(color: color),
          ),
        ],
      );
    }

    return Text(
      text,
      style: ZipBizTypography.labelLarge.copyWith(color: color),
    );
  }
}
