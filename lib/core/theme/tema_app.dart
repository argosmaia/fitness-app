import 'package:flutter/material.dart';

/// Define o tema visual premium do aplicativo (Dark Mode vibrante com glassmorphism).
class TemaApp {
  // Paleta de Cores
  static const Color corFundo = Color(0xFF0F0F12);
  static const Color corCard = Color(0xFF18181F);
  static const Color corCardBorda = Color(0xFF282833);

  static const Color corPrincipal = Color(0xFF00E676); // Esmeralda vibrante
  static const Color corSecundaria = Color(0xFF00B0FF); // Ciano/Azul piscina
  static const Color corAlerta = Color(
    0xFFFF3D00,
  ); // Vermelho vibrante para excessos
  static const Color corAviso = Color(
    0xFFFFB300,
  ); // Laranja para metas parciais

  static const Color corTextoPrincipal = Color(0xFFFFFFFF);
  static const Color corTextoSecundario = Color(0xFF8E8E9F);
  static const Color corTextoInativo = Color(0xFF4A4A5A);

  // Gradientes
  static const Gradient gradienteSaude = LinearGradient(
    colors: [corPrincipal, corSecundaria],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient gradienteFundoCard = LinearGradient(
    colors: [corCard, Color(0xFF1E1E28)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Gradient gradienteBotao = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Configuração ThemeData para o MaterialApp
  static ThemeData get temaEscuro {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: corFundo,
      cardColor: corCard,

      colorScheme: const ColorScheme.dark(
        primary: corPrincipal,
        secondary: corSecundaria,
        surface: corCard,
        error: corAlerta,
      ),

      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: corTextoPrincipal,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: corTextoPrincipal,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: corTextoPrincipal,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: corTextoPrincipal),
        bodyMedium: TextStyle(fontSize: 14, color: corTextoSecundario),
        labelSmall: TextStyle(
          fontSize: 11,
          color: corTextoInativo,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: corCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: corCardBorda, width: 1),
        ),
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: corTextoPrincipal,
        ),
        iconTheme: IconThemeData(color: corTextoPrincipal),
      ),

      sliderTheme: const SliderThemeData(
        activeTrackColor: corPrincipal,
        inactiveTrackColor: corCardBorda,
        thumbColor: corPrincipal,
        overlayColor: Color(0x2900E676),
      ),
    );
  }

  /// Efeito de sombra glassmorphism sutil para cards premium.
  static List<BoxShadow> get sombrasPremium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];
}
