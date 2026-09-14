import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/core/theme/theme_controller.dart';
import 'package:alize_mobile/core/widgets/lang_switcher.dart';
import 'package:alize_mobile/features/auth/presentation/pages/change_password_page.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:alize_mobile/features/settings/domain/entities/user_profile.dart';
import 'package:alize_mobile/features/settings/presentation/providers/settings_providers.dart';
import 'package:alize_mobile/features/settings/presentation/widgets/signature_pad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const currentPasswordFieldKey = Key('settings-password-current');
  static const newPasswordFieldKey = Key('settings-password-new');
  static const confirmPasswordFieldKey = Key('settings-password-confirm');
  static const signatureImageKey = Key('settings-signature-image');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends ConsumerStatefulWidget {
  const _SettingsView();

  @override
  ConsumerState<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<_SettingsView> {
  final _address = TextEditingController();
  final _postal = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController(text: 'FR');
  final _requestedTitle = TextEditingController();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _padKey = GlobalKey<SignaturePadState>();

  bool _filled = false;
  bool _savingPassword = false;
  String? _pwdError;

  @override
  void initState() {
    super.initState();
    _requestedTitle.addListener(_onChanged);
    _currentPassword.addListener(_onChanged);
    _newPassword.addListener(_onChanged);
    _confirmPassword.addListener(_onChanged);
  }

  @override
  void dispose() {
    _address.dispose();
    _postal.dispose();
    _city.dispose();
    _country.dispose();
    _requestedTitle
      ..removeListener(_onChanged)
      ..dispose();
    _currentPassword
      ..removeListener(_onChanged)
      ..dispose();
    _newPassword
      ..removeListener(_onChanged)
      ..dispose();
    _confirmPassword
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _fillFrom(UserProfile profile) {
    _address.text = profile.addressLine ?? '';
    _postal.text = profile.postalCode ?? '';
    _city.text = profile.city ?? '';
    _country.text = profile.country?.isNotEmpty == true
        ? profile.country!
        : 'FR';
    _filled = true;
  }

  bool get _tooShort =>
      _newPassword.text.isNotEmpty &&
      _newPassword.text.length < ChangePasswordPage.minLength;

  bool get _mismatch =>
      _confirmPassword.text.isNotEmpty &&
      _newPassword.text != _confirmPassword.text;

  bool get _canSubmitPassword =>
      !_savingPassword &&
      _currentPassword.text.isNotEmpty &&
      _newPassword.text.isNotEmpty &&
      !_tooShort &&
      !_mismatch;

  Future<void> _toast(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveAddress() async {
    final i18n = ref.read(i18nProvider);
    final result = await ref.read(settingsControllerProvider.notifier).saveAddress(
          addressLine: _address.text.trim(),
          postalCode: _postal.text.trim(),
          city: _city.text.trim(),
          country: _country.text.trim(),
        );
    await _toast(
      result.isOk ? i18n.t('settings.addressSaved') : i18n.t('settings.saveFail'),
    );
  }

  Future<void> _requestTitle() async {
    final title = _requestedTitle.text.trim();
    if (title.isEmpty) return;
    final i18n = ref.read(i18nProvider);
    final result =
        await ref.read(settingsControllerProvider.notifier).requestTitle(title);
    if (result.isOk) _requestedTitle.clear();
    await _toast(
      result.isOk ? i18n.t('settings.jobSent') : i18n.t('settings.jobSendFail'),
    );
  }

  Future<void> _cancelTitle() async {
    final i18n = ref.read(i18nProvider);
    final result =
        await ref.read(settingsControllerProvider.notifier).cancelTitle();
    await _toast(
      result.isOk ? i18n.t('settings.cancelled') : i18n.t('settings.cancelFail'),
    );
  }

  Future<void> _changePassword() async {
    if (!_canSubmitPassword) return;
    setState(() {
      _savingPassword = true;
      _pwdError = null;
    });
    final i18n = ref.read(i18nProvider);
    final result = await ref.read(authProvider.notifier).changePassword(
          currentPassword: _currentPassword.text,
          newPassword: _newPassword.text,
        );
    if (!mounted) return;
    if (result.isOk) {
      _currentPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      setState(() => _savingPassword = false);
      await _toast(i18n.t('settings.passwordUpdated'));
      return;
    }
    setState(() {
      _savingPassword = false;
      _pwdError = _passwordError(result.failure, i18n);
    });
  }

  String _passwordError(Failure? failure, I18nController i18n) {
    if (failure is ValidationFailure) return failure.message;
    if (failure is ServerFailure) {
      final message = failure.message;
      if (message != null && message.isNotEmpty) return message;
    }
    return i18n.t('settings.passwordFail');
  }

  Future<void> _saveSignature() async {
    final png = await _padKey.currentState?.snapshot();
    if (png == null) return;
    final i18n = ref.read(i18nProvider);
    final result =
        await ref.read(settingsControllerProvider.notifier).saveSignature(png);
    await _toast(
      result.isOk ? i18n.t('settings.sigSaved') : i18n.t('settings.saveFail'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final state = ref.watch(settingsControllerProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;
    ref.listen(settingsControllerProvider, (previous, next) {
      final loaded = next.profile;
      if (!_filled && loaded != null) {
        _fillFrom(loaded);
      }
    });
    final profile = state.profile;

    return Scaffold(
      backgroundColor: colors.paper,
      body: state.loading
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(i18n.t('common.loading')),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Text(
                  i18n.t('settings.title'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  i18n.t('settings.help'),
                  style: TextStyle(fontSize: 13, color: colors.ink2),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const LangSwitcher(),
                    const Spacer(),
                    IconButton(
                      tooltip: i18n.t('nav.theme'),
                      onPressed: () =>
                          ref.read(themeControllerProvider).toggle(),
                      icon: Icon(
                        Theme.of(context).brightness == Brightness.dark
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _JobCard(
                  colors: colors,
                  i18n: i18n,
                  profile: profile,
                  requestedTitle: _requestedTitle,
                  saving: state.savingTitle,
                  onRequest: _requestTitle,
                  onCancel: _cancelTitle,
                ),
                const SizedBox(height: 12),
                _AddressCard(
                  colors: colors,
                  i18n: i18n,
                  address: _address,
                  postal: _postal,
                  city: _city,
                  country: _country,
                  saving: state.savingAddress,
                  onSave: _saveAddress,
                ),
                const SizedBox(height: 12),
                _PasswordCard(
                  colors: colors,
                  i18n: i18n,
                  current: _currentPassword,
                  newPassword: _newPassword,
                  confirm: _confirmPassword,
                  tooShort: _tooShort,
                  mismatch: _mismatch,
                  canSubmit: _canSubmitPassword,
                  error: _pwdError,
                  onSubmit: _changePassword,
                ),
                const SizedBox(height: 12),
                _SignatureCard(
                  colors: colors,
                  i18n: i18n,
                  profile: profile,
                  padKey: _padKey,
                  saving: state.savingSig,
                  onSave: _saveSignature,
                  onClear: () => _padKey.currentState?.clear(),
                ),
              ],
            ),
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({
    required this.colors,
    required this.i18n,
    required this.profile,
    required this.requestedTitle,
    required this.saving,
    required this.onRequest,
    required this.onCancel,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final UserProfile? profile;
  final TextEditingController requestedTitle;
  final bool saving;
  final VoidCallback onRequest;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final pending = profile?.pendingJobTitle;
    return _Card(
      colors: colors,
      title: i18n.t('settings.job'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              text: '${i18n.t('settings.currentJob')} ',
              style: TextStyle(color: colors.ink2, fontSize: 14),
              children: [
                TextSpan(
                  text: (profile?.jobTitle == null || profile!.jobTitle!.isEmpty)
                      ? i18n.t('settings.unset')
                      : profile!.jobTitle!,
                  style: TextStyle(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (pending != null && pending.isNotEmpty) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.warnTint,
                borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Text(
                  i18n.t('settings.pendingHr', {'title': pending}),
                  style: TextStyle(color: colors.warn, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: saving ? null : onCancel,
                child: Text(i18n.t('settings.cancelRequest')),
              ),
            ),
          ] else ...[
            Text(
              i18n.t('settings.requestJob'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colors.ink2,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: requestedTitle,
              decoration: _inputDecoration(colors).copyWith(
                hintText: i18n.t('settings.jobPlaceholder'),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: saving || requestedTitle.text.trim().isEmpty
                    ? null
                    : onRequest,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brand,
                  foregroundColor: Colors.white,
                ),
                child: Text(i18n.t('settings.sendToHr')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.colors,
    required this.i18n,
    required this.address,
    required this.postal,
    required this.city,
    required this.country,
    required this.saving,
    required this.onSave,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final TextEditingController address;
  final TextEditingController postal;
  final TextEditingController city;
  final TextEditingController country;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      title: i18n.t('settings.address'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            colors: colors,
            label: i18n.t('settings.street'),
            controller: address,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  colors: colors,
                  label: i18n.t('settings.postal'),
                  controller: postal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  colors: colors,
                  label: i18n.t('settings.city'),
                  controller: city,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _LabeledField(
            colors: colors,
            label: i18n.t('settings.country'),
            controller: country,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: Colors.white,
              ),
              child: Text(
                saving ? i18n.t('common.saving') : i18n.t('settings.saveAddress'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordCard extends StatelessWidget {
  const _PasswordCard({
    required this.colors,
    required this.i18n,
    required this.current,
    required this.newPassword,
    required this.confirm,
    required this.tooShort,
    required this.mismatch,
    required this.canSubmit,
    required this.error,
    required this.onSubmit,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final TextEditingController current;
  final TextEditingController newPassword;
  final TextEditingController confirm;
  final bool tooShort;
  final bool mismatch;
  final bool canSubmit;
  final String? error;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return _Card(
      colors: colors,
      title: i18n.t('settings.password'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _LabeledField(
            key: SettingsPage.currentPasswordFieldKey,
            colors: colors,
            label: i18n.t('settings.currentPassword'),
            controller: current,
            obscure: true,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 12),
          _LabeledField(
            key: SettingsPage.newPasswordFieldKey,
            colors: colors,
            label: i18n.t('settings.newPassword'),
            controller: newPassword,
            obscure: true,
            autofillHints: const [AutofillHints.newPassword],
          ),
          const SizedBox(height: 12),
          _LabeledField(
            key: SettingsPage.confirmPasswordFieldKey,
            colors: colors,
            label: i18n.t('settings.confirmPassword'),
            controller: confirm,
            obscure: true,
            autofillHints: const [AutofillHints.newPassword],
          ),
          if (tooShort) ...[
            const SizedBox(height: 8),
            Text(
              i18n.t('settings.tooShort'),
              style: TextStyle(color: colors.bad, fontSize: 12.5),
            ),
          ],
          if (mismatch) ...[
            const SizedBox(height: 8),
            Text(
              i18n.t('settings.mismatch'),
              style: TextStyle(color: colors.bad, fontSize: 12.5),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              error!,
              style: TextStyle(color: colors.bad, fontSize: 12.5),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                backgroundColor: colors.brand,
                foregroundColor: Colors.white,
              ),
              child: Text(i18n.t('settings.changePassword')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureCard extends StatefulWidget {
  const _SignatureCard({
    required this.colors,
    required this.i18n,
    required this.profile,
    required this.padKey,
    required this.saving,
    required this.onSave,
    required this.onClear,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final UserProfile? profile;
  final GlobalKey<SignaturePadState> padKey;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onClear;

  @override
  State<_SignatureCard> createState() => _SignatureCardState();
}

class _SignatureCardState extends State<_SignatureCard> {
  bool _hasInk = false;

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final canDraw = profile == null || profile.canDrawSignature;
    final stored = _pngBytes(profile?.signaturePng);
    return _Card(
      colors: widget.colors,
      title: widget.i18n.t('settings.signature'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!canDraw) ...[
            if (stored != null)
              Image.memory(
                key: SettingsPage.signatureImageKey,
                stored,
                semanticLabel: widget.i18n.t('settings.yourSignature'),
                height: 120,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 12),
            Text(
              widget.i18n.t('settings.lockedHelp'),
              style: TextStyle(color: widget.colors.ink2, fontSize: 13),
            ),
          ] else ...[
            if (stored != null) ...[
              Text(
                widget.i18n.t('settings.replaceHelp'),
                style: TextStyle(color: widget.colors.ink2, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Image.memory(
                stored,
                semanticLabel: widget.i18n.t('settings.currentSignature'),
                height: 80,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  widget.i18n.t('settings.drawHelp'),
                  style: TextStyle(color: widget.colors.ink2, fontSize: 13),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: widget.colors.line),
                borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
                child: SizedBox(
                  height: 160,
                  child: Listener(
                    onPointerMove: (_) {
                      final ink = widget.padKey.currentState?.hasInk ?? false;
                      if (ink != _hasInk) setState(() => _hasInk = ink);
                    },
                    child: SignaturePad(key: widget.padKey),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () {
                    widget.onClear();
                    setState(() => _hasInk = false);
                  },
                  child: Text(widget.i18n.t('settings.clear')),
                ),
                FilledButton(
                  onPressed: widget.saving || !_hasInk ? null : widget.onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.colors.brand,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    widget.saving
                        ? widget.i18n.t('common.saving')
                        : widget.i18n.t('settings.saveSignature'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.colors,
    required this.title,
    required this.child,
  });

  final AlizePalette colors;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    super.key,
    required this.colors,
    required this.label,
    required this.controller,
    this.obscure = false,
    this.autofillHints,
  });

  final AlizePalette colors;
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.ink2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          autofillHints: autofillHints,
          decoration: _inputDecoration(colors),
        ),
      ],
    );
  }
}

InputDecoration _inputDecoration(AlizePalette colors) {
  return InputDecoration(
    filled: true,
    fillColor: colors.surface,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
      borderSide: BorderSide(color: colors.brand),
    ),
  );
}

Uint8List? _pngBytes(String? dataUrl) {
  if (dataUrl == null || dataUrl.isEmpty) return null;
  final comma = dataUrl.indexOf(',');
  if (comma < 0) return null;
  try {
    return base64Decode(dataUrl.substring(comma + 1));
  } catch (_) {
    return null;
  }
}
