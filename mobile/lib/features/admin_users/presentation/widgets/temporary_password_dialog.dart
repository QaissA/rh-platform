import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/features/admin_users/domain/entities/created_user.dart';
import 'package:alize_mobile/features/admin_users/presentation/user_labels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

String adminFailureMessage(Failure? failure, String fallback) {
  if (failure is ValidationFailure && failure.message.isNotEmpty) {
    return failure.message;
  }
  if (failure is ServerFailure) {
    final message = failure.message;
    if (message != null && message.isNotEmpty) return message;
  }
  return fallback;
}

Future<void> showTemporaryPasswordDialog({
  required BuildContext context,
  required I18nController i18n,
  required CreatedUser created,
  bool reset = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _TemporaryPasswordDialog(
      i18n: i18n,
      created: created,
      reset: reset,
    ),
  );
}

class _TemporaryPasswordDialog extends StatefulWidget {
  const _TemporaryPasswordDialog({
    required this.i18n,
    required this.created,
    required this.reset,
  });

  final I18nController i18n;
  final CreatedUser created;
  final bool reset;

  @override
  State<_TemporaryPasswordDialog> createState() =>
      _TemporaryPasswordDialogState();
}

class _TemporaryPasswordDialogState extends State<_TemporaryPasswordDialog> {
  var _copied = false;

  @override
  Widget build(BuildContext context) {
    final i18n = widget.i18n;
    final created = widget.created;
    return AlertDialog(
      title: Text(
        i18n.t(widget.reset ? 'users.resetTitle' : 'users.createdTitle'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.t('users.handover', {'name': userDisplayName(created.user)}),
          ),
          if (widget.reset) ...[
            const SizedBox(height: 8),
            Text(i18n.t('users.mustChange')),
          ],
          const SizedBox(height: 16),
          Text(i18n.t('common.email'), style: Theme.of(context).textTheme.labelSmall),
          SelectableText(created.user.email),
          const SizedBox(height: 12),
          Text(
            i18n.t('common.password'),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          SelectableText(
            created.temporaryPassword,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: created.temporaryPassword),
            );
            if (!mounted) return;
            setState(() => _copied = true);
          },
          child: Text(
            _copied ? i18n.t('common.copied') : i18n.t('common.copy'),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(i18n.t('common.close')),
        ),
      ],
    );
  }
}
