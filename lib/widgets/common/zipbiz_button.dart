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
  final EdgeInsetsGeometry? padding;

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
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (type == ZipBizButtonType.text) {
      return TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: ZipBizTypography.labelLarge.copyWith(
              color: ZipBizColors.primaryContainer,
            ),
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
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      return Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ZipBizTypography.labelLarge.copyWith(color: color),
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: ZipBizTypography.labelLarge.copyWith(color: color),
      ),
    );
  }
}

