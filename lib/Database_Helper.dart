import 'dart:developer' as dev;
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    const String databaseName = "Script_SQLite_Flutter.db";

    // Inicializa o sqflite para desktop
    sqfliteFfiInit();

    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, databaseName);
    dev.log("Database path: $path");

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await _criarTabelas(db);
        await _criarTriggers(db);
      },
      onOpen: (db) async {
        await _criarTabelas(db);
        await _criarTriggers(db);
      },
    );
  }

  static Future<void> _criarTabelas(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cadastro (
        texto TEXT NOT NULL,
        numero INTEGER PRIMARY KEY NOT NULL CHECK (numero > 0)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo_operacao TEXT,
        data_hora TEXT,
        numero INTEGER
      );
    ''');
  }

  static Future<void> _criarTriggers(Database db) async {
    // Trigger para INSERT
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_insert_log
      AFTER INSERT ON cadastro
      BEGIN
        INSERT INTO log (tipo_operacao, data_hora, numero)
        VALUES ('Insert', datetime('now'), NEW.numero);
      END;
    ''');

    // Trigger para UPDATE
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_update_log
      AFTER UPDATE ON cadastro
      BEGIN
        INSERT INTO log (tipo_operacao, data_hora, numero)
        VALUES ('Update', datetime('now'), NEW.numero);
      END;
    ''');

    // Trigger para DELETE
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_delete_log
      AFTER DELETE ON cadastro
      BEGIN
        INSERT INTO log (tipo_operacao, data_hora, numero)
        VALUES ('Delete', datetime('now'), OLD.numero);
      END;
    ''');
  }

  static Future<bool> verificarNumeroExistente(int numero) async {
    final db = await database;
    final result = await db.query(
      'cadastro',
      where: 'numero = ?',
      whereArgs: [numero],
    );
    return result.isNotEmpty;
  }

  static Future<void> inserirCadastro(String texto, int numero) async {
    final db = await database;
    await db.insert(
      'cadastro',
      {'texto': texto, 'numero': numero},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> atualizarCadastro(int numero, String texto) async {
    final db = await database;
    await db.update(
      'cadastro',
      {'texto': texto},
      where: 'numero = ?',
      whereArgs: [numero],
    );
  }

  static Future<void> excluirCadastro(int numero) async {
    final db = await database;
    await db.delete(
      'cadastro',
      where: 'numero = ?',
      whereArgs: [numero],
    );
  }

  static Future<List<Map<String, dynamic>>> listarCadastros() async {
    final db = await database;
    return await db.query('cadastro');
  }
}
