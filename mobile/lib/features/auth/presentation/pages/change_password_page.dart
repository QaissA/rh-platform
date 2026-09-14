import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/core/widgets/lang_switcher.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChangePasswordPage extends ConsumerWidget {
  const ChangePasswordPage({super.key});

  static const currentPasswordFieldKey = Key('change-password-current');
  static const newPasswordFieldKey = Key('change-password-new');
  static const confirmPasswordFieldKey = Key('change-password-confirm');
  static const minLength = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _ChangePasswordView(),
    );
  }
}

class _ChangePasswordView extends ConsumerStatefulWidget {
  const _ChangePasswordView();

  @override
  ConsumerState<_ChangePasswordView> createState() =>
      _ChangePasswordViewState();
}

class _ChangePasswordViewState extends ConsumerState<_ChangePasswordView> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _current.addListener(_onChanged);
    _new.addListener(_onChanged);
    _confirm.addListener(_onChanged);
  }

  @override
  void dispose() {
    _current
      ..removeListener(_onChanged)
      ..dispose();
    _new
      ..removeListener(_onChanged)
      ..dispose();
    _confirm
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _knowsTemp => ref.read(authProvider.notifier).hasTempPassword;

  bool get _tooShort => _new.text.length < ChangePasswordPage.minLength;

  bool get _mismatch =>
      _confirm.text.isNotEmpty && _new.text != _confirm.text;

  bool get _sameAsCurrent =>
      !_knowsTemp &&
      _new.text.isNotEmpty &&
      _new.text == _current.text;

  bool get _canSubmit =>
      !_loading &&
      (_knowsTemp || _current.text.isNotEmpty) &&
      !_tooShort &&
      !_mismatch &&
      !_sameAsCurrent;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final notifier = ref.read(authProvider.notifier);
    final result = _knowsTemp
        ? await notifier.changePasswordForced(_new.text)
        : await notifier.changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
          );
    if (!mounted) return;
    if (result.isOk) {
      setState(() => _loading = false);
      return;
    }
    final i18n = ref.read(i18nProvider);
    setState(() {
      _loading = false;
      _error = _errorText(result.failure, i18n);
    });
  }

  String _errorText(Failure? failure, I18nController i18n) {
    if (failure is NetworkFailure) return i18n.t('login.offline');
    if (failure is ValidationFailure) return failure.message;
    if (failure is ServerFailure) {
      final message = failure.message;
      if (message != null && message.isNotEmpty) return message;
    }
    return i18n.t('password.fail');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;

    return Scaffold(
      backgroundColor: colors.paper,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final form = _FormPane(
            colors: colors,
            current: _current,
            newPassword: _new,
            confirm: _confirm,
            knowsTemp: _knowsTemp,
            tooShort: _tooShort,
            mismatch: _mismatch,
            sameAsCurrent: _sameAsCurrent,
            canSubmit: _canSubmit,
            error: _error,
            loading: _loading,
            onSubmit: _submit,
          );
          if (!wide) {
            return SafeArea(child: form);
          }
          return Row(
            children: [
              const Expanded(flex: 105, child: _BrandPane()),
              Expanded(
                flex: 95,
                child: SafeArea(child: form),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BrandPane extends ConsumerWidget {
  const _BrandPane();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    const cream = Color(0xFFEFEAF9);
    const muted = Color(0xFFC9BCE8);
    final displayFamily =
        Theme.of(context).textTheme.headlineMedium?.fontFamily;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B0740), Color(0xFF460CAD), Color(0xFF08010F)],
          stops: [0, 0.48, 1],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 48, 40, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              i18n.t('brand'),
              style: TextStyle(
                fontFamily: displayFamily,
                color: cream,
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              i18n.t('password.headline'),
              style: TextStyle(
                fontFamily: displayFamily,
                color: cream,
                fontSize: 32,
                fontWeight: FontWeight.w500,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              i18n.t('password.pitch'),
              style: const TextStyle(color: muted, fontSize: 16, height: 1.4),
            ),
            const Spacer(),
            _Rule(text: i18n.t('password.ruleLength', {'n': 8})),
            const SizedBox(height: 10),
            _Rule(text: i18n.t('password.ruleDifferent')),
            const SizedBox(height: 10),
            _Rule(text: i18n.t('password.ruleSecret')),
          ],
        ),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✓',
          style: TextStyle(
            color: Color(0xFFB79BFF),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFFC9BCE8), fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _FormPane extends ConsumerWidget {
  const _FormPane({
    required this.colors,
    required this.current,
    required this.newPassword,
    required this.confirm,
    required this.knowsTemp,
    required this.tooShort,
    required this.mismatch,
    required this.sameAsCurrent,
    required this.canSubmit,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });

  final AlizePalette colors;
  final TextEditingController current;
  final TextEditingController newPassword;
  final TextEditingController confirm;
  final bool knowsTemp;
  final bool tooShort;
  final bool mismatch;
  final bool sameAsCurrent;
  final bool canSubmit;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final displayFamily =
        Theme.of(context).textTheme.headlineMedium?.fontFamily;
    final newHint = newPassword.text.isNotEmpty && tooShort
        ? i18n.t('password.tooShort')
        : sameAsCurrent
            ? i18n.t('password.sameAsTemp')
            : null;

    return ColoredBox(
      color: colors.paper,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 348),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerRight,
                  child: LangSwitcher(),
                ),
                const SizedBox(height: 18),
                Text(
                  i18n.t('password.title'),
                  style: TextStyle(
                    fontFamily: displayFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  i18n.t('password.subtitle'),
                  style: TextStyle(color: colors.ink2, fontSize: 15),
                ),
                const SizedBox(height: 28),
                if (!knowsTemp) ...[
                  _Field(
                    key: ChangePasswordPage.currentPasswordFieldKey,
                    controller: current,
                    label: i18n.t('password.temp'),
                    colors: colors,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => onSubmit(),
                  ),
                  const SizedBox(height: 16),
                ],
                _Field(
                  key: ChangePasswordPage.newPasswordFieldKey,
                  controller: newPassword,
                  label: i18n.t('password.new'),
                  colors: colors,
                  hint: newHint,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => onSubmit(),
                ),
                const SizedBox(height: 16),
                _Field(
                  key: ChangePasswordPage.confirmPasswordFieldKey,
                  controller: confirm,
                  label: i18n.t('password.confirm'),
                  colors: colors,
                  hint: mismatch ? i18n.t('password.mismatch') : null,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => onSubmit(),
                ),
                if (error != null) ...[
                  const SizedBox(height: 14),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.badTint,
                      border: Border.all(color: colors.bad),
                      borderRadius:
                          BorderRadius.circular(AlizeColors.radiusSm),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      child: Text(
                        error!,
                        style: TextStyle(color: colors.bad, fontSize: 13),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: canSubmit ? onSubmit : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: colors.brand.withValues(alpha: 0.45),
                    disabledForegroundColor: Colors.white70,
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AlizeColors.radiusSm),
                    ),
                  ),
                  child: loading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(i18n.t('password.submitting')),
                          ],
                        )
                      : Text(i18n.t('password.submit')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.label,
    required this.colors,
    this.hint,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final AlizePalette colors;
  final String? hint;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

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
        TextFormField(
          controller: controller,
          obscureText: true,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted,
          style: TextStyle(color: colors.ink, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
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
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(
            hint!,
            style: TextStyle(color: colors.bad, fontSize: 12.5),
          ),
        ],
      ],
    );
  }
}
