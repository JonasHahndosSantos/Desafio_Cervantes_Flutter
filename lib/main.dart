import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'pages/cadastro_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Desafio Cervantes',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Cor primária
        brightness: Brightness.dark, // Tema escuro
        scaffoldBackgroundColor: Colors.white10, // Fundo escuro suave
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blueGrey[900], // Cor da AppBar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.green, // Cor do texto
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Bordas arredondadas
            ),
          ),
        ),
        textTheme: TextTheme(
          displayLarge: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
          bodyLarge: TextStyle(fontSize: 18, color: Colors.white70),
        ),
      ),
      home: const CadastroPage(),
    );
  }
}

