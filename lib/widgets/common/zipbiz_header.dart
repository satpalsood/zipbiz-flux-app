import 'package:flutter/material.dart';
import '../../common/constants.dart';
import '../../routes/flux_navigate.dart';

class ZipBizLocationState {
  static final ValueNotifier<String> selectedLocation =
      ValueNotifier<String>('Mohali / Chandigarh');

  static void setLocation(String loc) {
    selectedLocation.value = loc;
  }
}

class ZipBizTopHeader extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showLocation;
  final bool showNotification;
  final Color? backgroundColor;

  const ZipBizTopHeader({
    super.key,
    this.showBackButton = false,
    this.onBack,
    this.showLocation = true,
    this.showNotification = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56.0);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor =
        backgroundColor ?? (isDark ? theme.colorScheme.surface : Colors.white);
    final textColor = isDark ? Colors.white : const Color(0xFF1B1C1E);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE4E2E1);

    return Container(
      color: bgColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 56.0,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              bottom: BorderSide(
                color: borderColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Back button (if enabled) + ZipBiz Logo
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showBackButton && Navigator.canPop(context))
                    Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: InkWell(
                        onTap: onBack ?? () => Navigator.of(context).maybePop(),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.arrow_back_ios_new,
                              size: 18, color: textColor),
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {},
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 30,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on,
                              color: Color(0xFFFF672D), size: 22),
                          const SizedBox(width: 4),
                          Text(
                            'ZipBiz',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Center: Location Dropdown Pill
              if (showLocation)
                InkWell(
                  onTap: () => showZipBizLocationPicker(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.08)
                          : const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on,
                            size: 15, color: Color(0xFFFF672D)),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 125),
                          child: ValueListenableBuilder<String>(
                            valueListenable:
                                ZipBizLocationState.selectedLocation,
                            builder: (context, location, _) {
                              return Text(
                                location,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.expand_more,
                            size: 16, color: Color(0xFF7A7B7F)),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),

              // Right: Notification Bell with Badge
              if (showNotification)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_outlined,
                          size: 24, color: textColor),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                      onPressed: () {
                        FluxNavigate.pushNamed(RouteList.notify,
                            context: context);
                      },
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF672D),
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '3',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(width: 32),
            ],
          ),
        ),
      ),
    );
  }
}

void showZipBizLocationPicker(BuildContext context) {
  final locations = [
    'Mohali / Chandigarh',
    'Chandigarh',
    'Mohali (SAS Nagar)',
    'Panchkula',
    'Zirakpur',
    'Kharar',
    'New Chandigarh',
    'Pinjore / Kalka',
    'Dera Bassi',
    'All Locations',
  ];

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
      final textColor = isDark ? Colors.white : const Color(0xFF1B1C1E);

      return Container(
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Your Location',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close, size: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Current GPS Location Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  ZipBizLocationState.setLocation('Mohali / Chandigarh');
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF672D).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFF672D).withOpacity(0.2)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.my_location,
                          size: 18, color: Color(0xFFFF672D)),
                      SizedBox(width: 10),
                      Text(
                        'Use Current Location (GPS)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF672D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            // Location List
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.45,
              ),
              child: ValueListenableBuilder<String>(
                valueListenable: ZipBizLocationState.selectedLocation,
                builder: (context, currentLoc, _) {
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: locations.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, indent: 48),
                    itemBuilder: (context, index) {
                      final loc = locations[index];
                      final isSelected = loc == currentLoc;
                      return ListTile(
                        leading: Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: isSelected
                              ? const Color(0xFFFF672D)
                              : Colors.grey,
                        ),
                        title: Text(
                          loc,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFFF672D)
                                : textColor,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle,
                                size: 18, color: Color(0xFFFF672D))
                            : null,
                        dense: true,
                        onTap: () {
                          ZipBizLocationState.setLocation(loc);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
