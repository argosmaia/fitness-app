import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../dashboard/presentation/home_shell.dart';
import 'auth_controller.dart';
import 'login_page.dart';
import 'verify_email_page.dart';

final class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(authControllerProvider)
      .when(
        loading: () =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (_, _) => const LoginPage(),
        data: (session) => session == null
            ? const LoginPage()
            : session.emailVerificationRequired
            ? VerifyEmailPage(email: session.user?.email ?? '')
            : HomeShell(user: session.user),
      );
}
