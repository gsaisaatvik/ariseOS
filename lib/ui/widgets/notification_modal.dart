import 'package:flutter/material.dart';

import 'primary_button.dart';
import 'secondary_button.dart';
import 'system_notification_card.dart';

/// System-styled confirmation / alert dialog (unified with overlays).
Future<void> showAriseNotificationDialog({
  required BuildContext context,
  required String title,
  required String message,
  Widget? messageWidget,
  SystemNotificationType type = SystemNotificationType.info,
  bool dangerButtons = false,
  String primaryLabel = 'OK',
  String? secondaryLabel,
  required VoidCallback onPrimary,
  VoidCallback? onSecondary,
}) {
  final secondary = secondaryLabel ?? 'NO';
  final twoButtons = secondaryLabel != null;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SystemNotificationCard(
        title: title,
        message: message,
        messageWidget: messageWidget,
        type: type,
        actions: twoButtons
            ? Row(
                children: [
                  Expanded(
                    child: PrimaryActionButton(
                      label: primaryLabel,
                      dangerTone: dangerButtons,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onPrimary();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SecondaryActionButton(
                      label: secondary,
                      dangerOutline: dangerButtons,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        onSecondary?.call();
                      },
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: double.infinity,
                child: PrimaryActionButton(
                  label: primaryLabel,
                  dangerTone: dangerButtons,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onPrimary();
                  },
                ),
              ),
      ),
    ),
  );
}

/// Binary system choice (e.g. directive commitment). Returns `true` for primary.
Future<bool?> showSystemBinaryDialog({
  required BuildContext context,
  required String title,
  required String message,
  SystemNotificationType type = SystemNotificationType.warning,
  bool dangerButtons = false,
  String primaryLabel = 'ACCEPT',
  String secondaryLabel = 'CANCEL',
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black87,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SystemNotificationCard(
        title: title,
        message: message,
        type: type,
        actions: Row(
          children: [
            Expanded(
              child: PrimaryActionButton(
                label: primaryLabel,
                dangerTone: dangerButtons,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecondaryActionButton(
                label: secondaryLabel,
                dangerOutline: dangerButtons,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
