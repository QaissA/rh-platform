import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/splash/presentation/widgets/alize_wave_mark.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _markCurve;
  late final CurvedAnimation _wordmarkCurve;
  late final CurvedAnimation _wordmarkSlideCurve;
  late final Animation<Offset> _wordmarkSlide;

  static const _totalDuration = Duration(milliseconds: 2000);
  static const _reducedDuration = Duration(milliseconds: 800);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration);

    _markCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );

    _wordmarkCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    _wordmarkSlideCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    _wordmarkSlide = Tween<Offset>(
      begin: const Offset(0, 12),
      end: Offset.zero,
    ).animate(_wordmarkSlideCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controller.isAnimating && _controller.value == 0) {
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _controller.duration = _reducedDuration;
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void dispose() {
    _wordmarkSlideCurve.dispose();
    _wordmarkCurve.dispose();
    _markCurve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.paper,
              colors.brandTint,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _markCurve,
                builder: (context, _) => AlizeWaveMark(
                  progress: _markCurve.value,
                  color: colors.brand,
                ),
              ),
              const SizedBox(height: 14),
              AnimatedBuilder(
                animation: _wordmarkCurve,
                builder: (context, child) => Opacity(
                  opacity: _wordmarkCurve.value,
                  child: Transform.translate(
                    offset: _wordmarkSlide.value,
                    child: child,
                  ),
                ),
                child: Text(
                  i18n.t('brand'),
                  style:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: colors.brand,
                            fontWeight: FontWeight.w700,
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
