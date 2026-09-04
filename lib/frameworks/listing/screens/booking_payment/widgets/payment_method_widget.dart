import 'package:flutter/material.dart';

import '../../../../../common/constants.dart';

class PaymentMethodWidget extends StatelessWidget {
  final bool isSelect;
  final String? title;
  final Widget? image;

  const PaymentMethodWidget(
      {super.key, required this.isSelect, this.image, required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 10.0,
      ),
      decoration: BoxDecoration(
        color: isSelect
            ? theme.primaryColor
            : theme.colorScheme.secondary.withValueOpacity(0.1),
        borderRadius: BorderRadius.circular(9.0),
      ),
      height: 110,
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (image != null) image!,
          if (image == null) ...[
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                title!,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                  color: isSelect
                      ? theme.primaryColor.getColorBasedOnBackground
                      : theme.colorScheme.secondary.getColorBasedOnBackground,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
