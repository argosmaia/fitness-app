import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import 'auth_controller.dart';

final class VerifyEmailPage extends ConsumerStatefulWidget {
  const VerifyEmailPage({super.key, required this.email});
  final String email;

  @override
  ConsumerState<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

final class _VerifyEmailPageState extends ConsumerState<VerifyEmailPage> {
  final _code = TextEditingController();
  Timer? _timer;
  int _seconds = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending || _seconds > 0) return;
    setState(() => _sending = true);
    try {
      await ref.read(authControllerProvider.notifier).sendEmailVerification();
      if (!mounted) return;
      setState(() => _seconds = 60);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || _seconds <= 1) {
          timer.cancel();
          if (mounted) setState(() => _seconds = 0);
        } else {
          setState(() => _seconds--);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código enviado. Verifique seu e-mail.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError(error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirm() async {
    if (_code.text.trim().length < 4) {
      _showError('Informe o código recebido.');
      return;
    }
    final success = await ref
        .read(authControllerProvider.notifier)
        .confirmEmailVerification(_code.text);
    if (!success && mounted) {
      _showError(ref.read(authControllerProvider).error ?? 'Código inválido.');
    }
  }

  void _showError(Object error) {
    final message = error is AppException ? error.message : error.toString();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(authControllerProvider).isLoading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 72),
                  const SizedBox(height: 24),
                  Text(
                    'Confirme seu e-mail',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enviamos um código para ${widget.email}.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _code,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _confirm(),
                    decoration: const InputDecoration(
                      labelText: 'Código de verificação',
                      prefixIcon: Icon(Icons.password),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: busy ? null : _confirm,
                    child: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Confirmar e continuar'),
                  ),
                  TextButton(
                    onPressed: _sending || _seconds > 0 ? null : _send,
                    child: Text(
                      _seconds > 0
                          ? 'Reenviar em ${_seconds}s'
                          : 'Reenviar código',
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : ref.read(authControllerProvider.notifier).logout,
                    child: const Text('Usar outra conta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
