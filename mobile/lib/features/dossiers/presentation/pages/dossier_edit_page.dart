import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:alize_mobile/core/format/dates.dart';
import 'package:alize_mobile/core/l10n/i18n_provider.dart';
import 'package:alize_mobile/core/theme/alize_colors.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/update_dossier.dart';
import 'package:alize_mobile/features/dossiers/domain/entities/user_dossier.dart';
import 'package:alize_mobile/features/dossiers/presentation/providers/dossier_providers.dart';
import 'package:alize_mobile/features/settings/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DossierEditPage extends ConsumerStatefulWidget {
  const DossierEditPage({super.key, required this.id});

  static const salaryFieldKey = Key('dossier-salary');

  final int id;

  @override
  ConsumerState<DossierEditPage> createState() => _DossierEditPageState();
}

class _DossierEditPageState extends ConsumerState<DossierEditPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _jobTitle = TextEditingController();
  final _address = TextEditingController();
  final _postal = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController(text: 'FR');
  final _salary = TextEditingController();
  final _iban = TextEditingController();

  var _loading = true;
  var _saving = false;
  var _unlocking = false;
  UserDossier? _dossier;
  String _contractType = '';
  String _hiredOn = '';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _jobTitle.dispose();
    _address.dispose();
    _postal.dispose();
    _city.dispose();
    _country.dispose();
    _salary.dispose();
    _iban.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result =
        await ref.read(dossierRepositoryProvider).getDossier(widget.id);
    if (!mounted) return;
    final dossier = result.data;
    if (!result.isOk || dossier == null) {
      setState(() => _loading = false);
      return;
    }
    _fill(dossier);
  }

  void _fill(UserDossier dossier) {
    final profile = dossier.profile;
    _firstName.text = profile.firstName ?? '';
    _lastName.text = profile.lastName ?? '';
    _jobTitle.text = profile.jobTitle ?? '';
    _address.text = profile.addressLine ?? '';
    _postal.text = profile.postalCode ?? '';
    _city.text = profile.city ?? '';
    _country.text =
        profile.country != null && profile.country!.isNotEmpty
            ? profile.country!
            : 'FR';
    _salary.text = _eurosInput(dossier.salaryCents);
    _iban.text = dossier.iban ?? '';
    setState(() {
      _dossier = dossier;
      _contractType = dossier.contractType ?? '';
      _hiredOn = dossier.hiredOn ?? '';
      _loading = false;
      _saving = false;
      _unlocking = false;
    });
  }

  Future<void> _toast(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _save() async {
    final dossier = _dossier;
    if (dossier == null || _saving) return;
    setState(() => _saving = true);
    final i18n = ref.read(i18nProvider);
    final euros = _parseEuros(_salary.text);
    if (_salary.text.trim().isNotEmpty && euros == null) {
      setState(() => _saving = false);
      await _toast(i18n.t('dossiers.saveFail'));
      return;
    }
    final job = _jobTitle.text.trim();
    final result = await ref.read(dossierRepositoryProvider).updateDossier(
          dossier.id,
          UpdateDossier(
            firstName: _firstName.text.trim(),
            lastName: _lastName.text.trim(),
            jobTitle: job.isEmpty ? null : job,
            addressLine: _address.text.trim(),
            postalCode: _postal.text.trim(),
            city: _city.text.trim(),
            country: _country.text.trim().isEmpty ? 'FR' : _country.text.trim(),
            salaryCents: salaryCentsFromEuros(euros),
            contractType: _contractType.isEmpty ? null : _contractType,
            hiredOn: _hiredOn.isEmpty ? null : _hiredOn,
            iban: _iban.text.trim().isEmpty ? null : _iban.text.trim(),
          ),
        );
    if (!mounted) return;
    if (!result.isOk || result.data == null) {
      setState(() => _saving = false);
      await _toast(i18n.t('dossiers.saveFail'));
      return;
    }
    _fill(result.data!);
    await _toast(i18n.t('dossiers.saved'));
  }

  Future<void> _unlock() async {
    final dossier = _dossier;
    if (dossier == null || _unlocking) return;
    setState(() => _unlocking = true);
    final i18n = ref.read(i18nProvider);
    final result =
        await ref.read(dossierRepositoryProvider).unlockSignature(dossier.id);
    if (!mounted) return;
    if (!result.isOk || result.data == null) {
      setState(() => _unlocking = false);
      await _toast(i18n.t('dossiers.unlockFail'));
      return;
    }
    _fill(result.data!);
    await _toast(i18n.t('dossiers.unlocked'));
  }

  Future<void> _pickHiredOn() async {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(_hiredOn);
    final picked = await showDatePicker(
      context: context,
      initialDate: parsed ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null || !mounted) return;
    setState(() => _hiredOn = isoDate(picked));
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(i18nProvider);
    final colors = Theme.of(context).brightness == Brightness.dark
        ? AlizeColors.dark
        : AlizeColors.light;
    final dossier = _dossier;
    final profile = dossier?.profile;

    return Directionality(
      textDirection:
          i18n.dir == 'rtl' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: colors.paper,
        body: _loading
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
            : dossier == null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _BackButton(i18n: i18n),
                      Text(
                        i18n.t('dossiers.notFound'),
                        style: TextStyle(color: colors.ink2),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_firstName.text} ${_lastName.text}'.trim(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: colors.ink,
                                  ),
                                ),
                                if (_jobTitle.text.trim().isNotEmpty)
                                  Text(
                                    _jobTitle.text.trim(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colors.ink2,
                                    ),
                                  ),
                                Text(
                                  profile?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colors.ink3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.go('/dossiers'),
                            child: Text(i18n.t('dossiers.back')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if ((profile?.pendingJobTitle ?? '').trim().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _Card(
                            colors: colors,
                            warn: true,
                            child: Text(
                              i18n.t('dossiers.pendingBanner', {
                                'title': profile!.pendingJobTitle ?? '',
                              }),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.warn,
                              ),
                            ),
                          ),
                        ),
                      _Card(
                        colors: colors,
                        title: i18n.t('dossiers.identity'),
                        child: Column(
                          children: [
                            _LabeledField(
                              colors: colors,
                              label: i18n.t('common.firstName'),
                              controller: _firstName,
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              colors: colors,
                              label: i18n.t('common.lastName'),
                              controller: _lastName,
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              colors: colors,
                              label: i18n.t('dossiers.job'),
                              controller: _jobTitle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Card(
                        colors: colors,
                        title: i18n.t('settings.address'),
                        child: Column(
                          children: [
                            _LabeledField(
                              colors: colors,
                              label: i18n.t('settings.street'),
                              controller: _address,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _LabeledField(
                                    colors: colors,
                                    label: i18n.t('settings.postal'),
                                    controller: _postal,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _LabeledField(
                                    colors: colors,
                                    label: i18n.t('settings.city'),
                                    controller: _city,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              colors: colors,
                              label: i18n.t('settings.country'),
                              controller: _country,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Card(
                        colors: colors,
                        title: i18n.t('dossiers.confidential'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              i18n.t('dossiers.confidentialHelp'),
                              style: TextStyle(
                                fontSize: 13,
                                color: colors.ink2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              key: DossierEditPage.salaryFieldKey,
                              colors: colors,
                              label: i18n.t('dossiers.salary'),
                              controller: _salary,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              i18n.t('dossiers.contract'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            InputDecorator(
                              decoration: _inputDecoration(colors),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _contractType,
                                  isExpanded: true,
                                  items: [
                                    DropdownMenuItem(
                                      value: '',
                                      child: Text(i18n.t('common.dash')),
                                    ),
                                    for (final code in contractTypes)
                                      DropdownMenuItem(
                                        value: code,
                                        child: Text(
                                          i18n.t('status.contract.$code'),
                                        ),
                                      ),
                                  ],
                                  onChanged: _saving
                                      ? null
                                      : (value) {
                                          setState(
                                            () => _contractType = value ?? '',
                                          );
                                        },
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              i18n.t('dossiers.hiredOn'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colors.ink2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Material(
                              color: colors.surface,
                              child: InkWell(
                                onTap: _pickHiredOn,
                                borderRadius: BorderRadius.circular(
                                  AlizeColors.radiusSm,
                                ),
                                child: InputDecorator(
                                  decoration: _inputDecoration(colors),
                                  child: Text(
                                    _hiredOn.isEmpty
                                        ? i18n.t('common.dash')
                                        : formatDay(_hiredOn),
                                    style: TextStyle(
                                      color: _hiredOn.isEmpty
                                          ? colors.ink3
                                          : colors.ink,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _LabeledField(
                              colors: colors,
                              label: i18n.t('dossiers.iban'),
                              controller: _iban,
                              autocorrect: false,
                              enableSuggestions: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.brand,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            _saving
                                ? i18n.t('common.saving')
                                : i18n.t('dossiers.saveDossier'),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SignatureCard(
                        colors: colors,
                        i18n: i18n,
                        profile: profile,
                        unlocking: _unlocking,
                        onUnlock: _unlock,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.i18n});

  final I18nController i18n;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => context.go('/dossiers'),
        child: Text(i18n.t('dossiers.back')),
      ),
    );
  }
}

class _SignatureCard extends StatelessWidget {
  const _SignatureCard({
    required this.colors,
    required this.i18n,
    required this.profile,
    required this.unlocking,
    required this.onUnlock,
  });

  final AlizePalette colors;
  final I18nController i18n;
  final UserProfile? profile;
  final bool unlocking;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final png = _pngBytes(profile?.signaturePng);
    final locked = profile?.signatureLocked ?? false;
    return _Card(
      colors: colors,
      title: i18n.t('dossiers.signature'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (png != null) ...[
            Image.memory(
              png,
              semanticLabel: i18n.t('dossiers.signature'),
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 12),
            if (locked) ...[
              Text(
                i18n.t('dossiers.locked'),
                style: TextStyle(fontSize: 13, color: colors.ink2),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton(
                  onPressed: unlocking ? null : onUnlock,
                  child: Text(i18n.t('dossiers.unlock')),
                ),
              ),
            ] else
              Text(
                i18n.t('dossiers.awaitingSig'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.warn,
                ),
              ),
          ] else
            Text(
              i18n.t('dossiers.noSig'),
              style: TextStyle(fontSize: 13, color: colors.ink2),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.colors,
    required this.child,
    this.title,
    this.warn = false,
  });

  final AlizePalette colors;
  final String? title;
  final bool warn;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AlizeColors.radius),
        border: Border.all(color: warn ? colors.warn : colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 12),
            ],
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
    this.keyboardType,
    this.autocorrect = true,
    this.enableSuggestions = true,
  });

  final AlizePalette colors;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool autocorrect;
  final bool enableSuggestions;

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
          keyboardType: keyboardType,
          autocorrect: autocorrect,
          enableSuggestions: enableSuggestions,
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

String _eurosInput(int? cents) {
  if (cents == null) return '';
  final euros = cents / 100;
  if (euros == euros.roundToDouble()) return '${euros.round()}';
  return euros.toString();
}

num? _parseEuros(String raw) {
  final trimmed = raw.trim().replaceAll(',', '.');
  if (trimmed.isEmpty) return null;
  return num.tryParse(trimmed);
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
