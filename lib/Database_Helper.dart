import 'dart:developer' as dev;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _database;

  // Método para obter a instância do banco de dados
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Inicializa o banco de dados
  static Future<Database> _initDatabase() async {
    final String databaseName = "Script_SQLite_Flutter.db";

    // Configura o sqflite para rodar em desktop
    sqfliteFfiInit();

    // Verifica se é mobile ou desktop e define o caminho do banco de dados
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, databaseName);
    dev.log("Database path: $path");

    bool dbExists = await File(path).exists();

    if (!dbExists) {
      // Caso o banco não exista, carrega um banco padrão a partir dos assets
      ByteData data = await rootBundle.load("assets/Script_SQLite_Flutter.db");
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
    }

    // Abre o banco de dados
    return await openDatabase(path);
  }

  /// Cria a tabela de log
  static Future<void> criarTabelaLog() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo_operacao TEXT,
        data_hora TEXT,
        numero INTEGER
      );
    ''');
  }

  /// Cria a tabela cadastro com validações
  static Future<void> criarTabelaCadastro() async {
    final db = await database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cadastro (
        texto TEXT NOT NULL,
        numero INTEGER PRIMARY KEY NOT NULL CHECK (numero > 0)
      );
    ''');
  }

  /// Registra a operação no log
  static Future<void> registrarLog(String tipoOperacao, int numero) async {
    final db = await database;
    await db.insert(
      'log',
      {
        'tipo_operacao': tipoOperacao,
        'data_hora': DateTime.now().toIso8601String(),
        'numero': numero,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Verifica se o número já existe na tabela 'cadastro'
  static Future<bool> verificarNumeroExistente(int numero) async {
    final db = await database;
    final result = await db.query(
      'cadastro',
      where: 'numero = ?',
      whereArgs: [numero],
    );
    return result.isNotEmpty;
  }

  /// Insere um novo registro na tabela 'cadastro'
  static Future<void> inserirCadastro(String texto, int numero) async {
    final db = await database;
    await db.insert(
      'cadastro',
      {'texto': texto, 'numero': numero},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await registrarLog('Insert', numero); // Registrar no log
  }

  /// Atualiza o registro com base no valor do número
  static Future<void> atualizarCadastro(int numero, String texto) async {
    final db = await database;
    await db.update(
      'cadastro',
      {'texto': texto},
      where: 'numero = ?',
      whereArgs: [numero],
    );
    await registrarLog('Update', numero); // Registrar no log
  }

  /// Exclui o registro com base no valor do número
  static Future<void> excluirCadastro(int numero) async {
    final db = await database;
    await db.delete(
      'cadastro',
      where: 'numero = ?',
      whereArgs: [numero],
    );
    await registrarLog('Delete', numero); // Registrar no log
  }

  /// Lista todos os registros da tabela 'cadastro'
  static Future<List<Map<String, dynamic>>> listarCadastros() async {
    final db = await database;
    return await db.query('cadastro');
  }
}
