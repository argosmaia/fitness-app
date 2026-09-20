# Fluxo de Autenticação e Boas-vindas (UI)

Este documento guarda as especificações visuais e de fluxo de telas para a equipe de frontend.

## 1. Página de Login e Registro

A tela de entrada deve ser uma página típica de boas-vindas contendo duas ações principais: **Login** e **Registrar**.

### Regras de Negócio:
*   **Login:**
    *   Deve permitir autenticação com **E-mail e Senha**.
    *   Deve permitir **Login com Google** (SSO).
*   **Registro:**
    *   Deve permitir o registro comum preenchendo o formulário manualmente.
    *   Deve permitir o **Registro via Google**, onde o aplicativo aproveita a integração para puxar dados do **Google Health** (como medidas e histórico) para facilitar o preenchimento do perfil (onboarding).

---

## 2. Código Base de UI (Gerado)

Os códigos Flutter abaixo servem como base para a construção das telas `WelcomePageWidget` e `HomePageWidget`. 

> **Aviso:** Como o código colado no chat era muito grande, apenas a estrutura inicial foi salva aqui. É recomendado que os arquivos `.dart` completos (como exportados do FlutterFlow) sejam colocados diretamente no repositório final do aplicativo Flutter, em vez de ficarem colados nos documentos Markdown.

### WelcomePageWidget (Base)
```dart
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'welcome_page_model.dart';
export 'welcome_page_model.dart';

class WelcomePageWidget extends StatefulWidget {
  const WelcomePageWidget({super.key});

  static String routeName = 'WelcomePage';
  static String routePath = 'welcomePage';

  @override
  State<WelcomePageWidget> createState() => _WelcomePageWidgetState();
}

class _WelcomePageWidgetState extends State<WelcomePageWidget> {
  late WelcomePageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => WelcomePageModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ... (build method com a UI de boas vindas, logo, etc)
}
```

### HomePageWidget (Base)
```dart
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:math';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';

import 'home_page_model.dart';
export 'home_page_model.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  static String routeName = 'HomePage';
  static String routePath = 'homePage';

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

// ... (Animações, charts e UI do Dashboard principal)
```
