import 'package:flutter/material.dart';
import '../../core/theme/zipbiz_colors.dart';
import '../../core/theme/zipbiz_typography.dart';

enum ZipBizBadgeVariant {
  verified,
  open,
  closed,
  topRated,
  category,
  neutral,
}

class ZipBizBadge extends StatelessWidget {
  final String text;
  final ZipBizBadgeVariant variant;
  final IconData? icon;

  const ZipBizBadge({
    super.key,
    required this.text,
    this.variant = ZipBizBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData? defaultIcon;

    switch (variant) {
      case ZipBizBadgeVariant.verified:
        bg = ZipBizColors.surfaceContainerLowest;
        fg = ZipBizColors.primary;
        defaultIcon = Icons.verified;
        break;
      case ZipBizBadgeVariant.open:
        bg = ZipBizColors.statusOpen.withOpacity(0.12);
        fg = ZipBizColors.statusOpen;
        defaultIcon = Icons.circle;
        break;
      case ZipBizBadgeVariant.closed:
        bg = ZipBizColors.statusClosed.withOpacity(0.12);
        fg = ZipBizColors.statusClosed;
        defaultIcon = Icons.cancel;
        break;
      case ZipBizBadgeVariant.topRated:
        bg = ZipBizColors.primaryFixed;
        fg = ZipBizColors.onPrimaryFixedVariant;
        defaultIcon = Icons.star;
        break;
      case ZipBizBadgeVariant.category:
        bg = ZipBizColors.secondaryFixed;
        fg = ZipBizColors.onSecondaryFixedVariant;
        break;
      case ZipBizBadgeVariant.neutral:
      default:
        bg = ZipBizColors.surfaceContainer;
        fg = ZipBizColors.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: (variant == ZipBizBadgeVariant.verified)
            ? Border.all(color: ZipBizColors.outlineVariant.withOpacity(0.5), width: 0.5)
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null || defaultIcon != null) ...[
            Icon(icon ?? defaultIcon, size: (variant == ZipBizBadgeVariant.open) ? 8 : 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: ZipBizTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
