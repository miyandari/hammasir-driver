import 'package:flutter/material.dart';

import 'package:hammasir_driver/app/settings_scope.dart';
import 'package:hammasir_driver/core/theme/app_palette.dart';
import 'package:hammasir_driver/core/widgets/brand_mark.dart';
import 'package:hammasir_driver/core/widgets/soft_banner.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/l10n/l10n.dart';
import 'package:hammasir_driver/state/session_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session});

  final SessionController session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final error = await widget.session.login(_username.text, _password.text);
    if (!mounted) return;
    setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final locale = SettingsScope.of(context).locale;

    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        final busy = widget.session.busy;
        final notice = widget.session.notice;

        return Scaffold(
          backgroundColor: p.brand,
          resizeToAvoidBottomInset: true,
          body: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: _LanguageToggle(
                      code: locale.code,
                      onChanged: locale.setLanguage,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    BrandMark(size: 96, lineColor: Colors.white, accent: p.accent),
                    const SizedBox(height: 10),
                    Text(
                      context.t('app.name'),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.t('app.tagline'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            context.t('login.title'),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.t('login.subtitle'),
                            style: TextStyle(color: p.textMuted),
                          ),
                          const SizedBox(height: 22),
                          if (notice != null) ...[
                            SoftBanner(
                              message: notice,
                              tone: Tone.warning,
                              icon: Icons.info_outline,
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _username,
                            enabled: !busy,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: context.t('login.username'),
                              prefixIcon: const Icon(Icons.person_outline),
                            ),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                    ? context.t('login.username_required')
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            enabled: !busy,
                            obscureText: _hidePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            textDirection: TextDirection.ltr,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: context.t('login.password'),
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                tooltip: _hidePassword
                                    ? context.t('login.show_password')
                                    : context.t('login.hide_password'),
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _hidePassword = !_hidePassword,
                                ),
                              ),
                            ),
                            validator: (value) =>
                                (value == null || value.isEmpty)
                                    ? context.t('login.password_required')
                                    : null,
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 14),
                            SoftBanner(
                              message: _error!,
                              tone: Tone.danger,
                              icon: Icons.error_outline,
                            ),
                          ],
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: busy ? null : _submit,
                            child: busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(context.t('login.submit')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// کلید کوچک تغییر زبان روی صفحه‌ی ورود.
class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.code, required this.onChanged});

  final String code;
  final void Function(String code) onChanged;

  @override
  Widget build(BuildContext context) {
    Widget item(String value, String label) {
      final selected = code == value;
      return GestureDetector(
        onTap: () => onChanged(value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? context.palette.brand : Colors.white,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [item('fa', 'فارسی'), item('en', 'English')],
      ),
    );
  }
}
