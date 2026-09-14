import 'package:alize_mobile/core/error/failures.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/core/widgets/lang_switcher.dart';
import 'package:alize_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  static const emailFieldKey = Key('login-email');
  static const passwordFieldKey = Key('login-password');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: const _LoginView(),
    );
  }
}

class _LoginView extends ConsumerStatefulWidget {
  const _LoginView();

  @override
  ConsumerState<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<_LoginView> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;

  static const _demos = <(String, String)>[
    ('employee@rh.local', 'login.demoEmployee'),
    ('manager@rh.local', 'login.demoManager'),
    ('rh@rh.local', 'login.demoRh'),
    ('admin@rh.local', 'common.role.admin'),
  ];

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref.read(authProvider.notifier).login(
          _email.text,
          _password.text,
        );
    if (!mounted) return;
    if (result.isOk) {
      setState(() => _loading = false);
      return;
    }
    final i18n = ref.read(i18nProvider);
    setState(() {
      _loading = false;
      _error = result.failure is NetworkFailure
          ? i18n.t('login.offline')
          : i18n.t('login.badCredentials');
    });
  }

  void _fillDemo(String email) {
    _email.text = email;
    _password.text = 'password';
  }

  @override
  Widget build(BuildContext context) {
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
            email: _email,
            password: _password,
            error: _error,
            loading: _loading,
            onSubmit: _submit,
            onFillDemo: _fillDemo,
            demos: _demos,
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
                fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
                color: cream,
                fontSize: 26,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              i18n.t('login.headline'),
              style: TextStyle(
                fontFamily: Theme.of(context).textTheme.headlineMedium?.fontFamily,
                color: cream,
                fontSize: 32,
                fontWeight: FontWeight.w500,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              i18n.t('login.pitch'),
              style: const TextStyle(color: muted, fontSize: 16, height: 1.4),
            ),
            const Spacer(),
            Wrap(
              spacing: 28,
              runSpacing: 12,
              children: [
                _Stat(value: '18,5', label: i18n.t('login.statBalance')),
                _Stat(value: '7', label: i18n.t('login.statTeammates')),
                _Stat(value: '2', label: i18n.t('login.statPending')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFEFEAF9),
            fontSize: 24,
            fontWeight: FontWeight.w500,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0A1D4),
            fontSize: 12,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _FormPane extends ConsumerWidget {
  const _FormPane({
    required this.colors,
    required this.email,
    required this.password,
    required this.error,
    required this.loading,
    required this.onSubmit,
    required this.onFillDemo,
    required this.demos,
  });

  final AlizePalette colors;
  final TextEditingController email;
  final TextEditingController password;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;
  final void Function(String email) onFillDemo;
  final List<(String, String)> demos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(i18nProvider);
    final displayFamily =
        Theme.of(context).textTheme.headlineMedium?.fontFamily;

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
                  i18n.t('login.welcome'),
                  style: TextStyle(
                    fontFamily: displayFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: colors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  i18n.t('login.subtitle'),
                  style: TextStyle(color: colors.ink2, fontSize: 15),
                ),
                const SizedBox(height: 28),
                _Field(
                  key: LoginPage.emailFieldKey,
                  controller: email,
                  label: i18n.t('login.email'),
                  colors: colors,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  obscureText: false,
                  onSubmitted: (_) => onSubmit(),
                ),
                const SizedBox(height: 16),
                _Field(
                  key: LoginPage.passwordFieldKey,
                  controller: password,
                  label: i18n.t('login.password'),
                  colors: colors,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
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
                  onPressed: loading ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.brand,
                    foregroundColor: Colors.white,
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
                            Text(i18n.t('login.submitting')),
                          ],
                        )
                      : Text(i18n.t('login.submit')),
                ),
                const SizedBox(height: 20),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.brandTint,
                    border: Border.all(
                      color: colors.brand600,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(AlizeColors.radiusSm),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(13, 11, 13, 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          i18n.t('login.demos'),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.brandInk,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final demo in demos)
                              _DemoChip(
                                label: i18n.t(demo.$2),
                                colors: colors,
                                onPressed: () => onFillDemo(demo.$1),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
    required this.obscureText,
    this.keyboardType,
    this.autofillHints,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final AlizePalette colors;
  final bool obscureText;
  final TextInputType? keyboardType;
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
          obscureText: obscureText,
          keyboardType: keyboardType,
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
      ],
    );
  }
}

class _DemoChip extends StatelessWidget {
  const _DemoChip({
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final AlizePalette colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.brandInk,
        backgroundColor: colors.brandTint,
        side: BorderSide(color: colors.brand600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }
}
