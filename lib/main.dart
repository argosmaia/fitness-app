import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/db/gerenciador_banco_dados.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GerenciadorBancoDados.configurarPlataforma();
  runApp(const ProviderScope(child: FitnessApp()));
}
