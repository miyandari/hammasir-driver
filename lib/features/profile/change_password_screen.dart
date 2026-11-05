import 'package:flutter/material.dart';

import 'package:hammasir_driver/app/deps.dart';
import 'package:hammasir_driver/core/network/api_exception.dart';
import 'package:hammasir_driver/core/widgets/soft_banner.dart';
import 'package:hammasir_driver/core/widgets/status_chip.dart';
import 'package:hammasir_driver/features/shared/ui_helpers.dart';
import 'package:hammasir_driver/l10n/l10n.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _repeat = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _repeat.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final deps = DepsScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await deps.auth.changePassword(current: _current.text, next: _next.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      showMessage(context, context.t('pw.changed'), tone: Tone.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    }
  }

  Widget _field(
    TextEditingController controller,
    String label,
    String? Function(String?) validator,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: !_busy,
        obscureText: true,
        textDirection: TextDirection.ltr,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t('pw.title'))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _field(
              _current,
              context.t('pw.current'),
              (v) => (v == null || v.isEmpty)
                  ? context.t('pw.current_required')
                  : null,
            ),
            _field(
              _next,
              context.t('pw.new'),
              (v) => (v == null || v.length < 8)
                  ? context.t('pw.new_short')
                  : null,
            ),
            _field(
              _repeat,
              context.t('pw.repeat'),
              (v) => v != _next.text ? context.t('pw.mismatch') : null,
            ),
            if (_error != null) ...[
              SoftBanner(
                message: _error!,
                tone: Tone.danger,
                icon: Icons.error_outline,
              ),
              const SizedBox(height: 14),
            ],
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(context.t('common.save')),
            ),
          ],
        ),
      ),
    );
  }
}
