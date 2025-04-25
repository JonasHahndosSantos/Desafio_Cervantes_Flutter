import 'package:flutter/material.dart';
import '../database_helper.dart';

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _formKey = GlobalKey<FormState>();
  final _textoController = TextEditingController();
  final _numeroController = TextEditingController();
  List<Map<String, dynamic>> _cadastros = [];

  bool _modoAtualizacao = false;
  int? _numeroAtualizacao;

  @override
  void initState() {
    super.initState();
    _carregarCadastros();
  }

  Future<void> _carregarCadastros() async {
    final dados = await DatabaseHelper.listarCadastros();
    setState(() {
      _cadastros = dados;
    });
  }

  Future<void> _salvarCadastro() async {
    if (_formKey.currentState!.validate()) {
      final texto = _textoController.text;
      final numero = int.parse(_numeroController.text);

      if (_modoAtualizacao) {
        await DatabaseHelper.atualizarCadastro(numero, texto);
        _mostrarMensagem('Cadastro atualizado com sucesso!');
      } else {
        final jaExiste = await DatabaseHelper.verificarNumeroExistente(numero);
        if (jaExiste) {
          _mostrarMensagem('Número já cadastrado!');
          return;
        }
        await DatabaseHelper.inserirCadastro(texto, numero);
        _mostrarMensagem('Cadastro salvo com sucesso!');
      }

      _textoController.clear();
      _numeroController.clear();
      _modoAtualizacao = false;
      _numeroAtualizacao = null;
      await _carregarCadastros();
    }
  }

  void _editarCadastro(Map<String, dynamic> item) {
    setState(() {
      _modoAtualizacao = true;
      _numeroAtualizacao = item['numero'];
      _textoController.text = item['texto'];
      _numeroController.text = item['numero'].toString();

    });
  }

  Future<void> _excluirCadastro(int numero) async {
    await DatabaseHelper.excluirCadastro(numero);
    _mostrarMensagem('Cadastro excluído com sucesso!');
    await _carregarCadastros();
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _confirmarExclusao(int numero) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmação'),
        content: const Text('Deseja realmente excluir este cadastro?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await _excluirCadastro(numero);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.app_registration, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Cadastro',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 300,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _textoController,
                        decoration: const InputDecoration(labelText: 'Texto'),
                        validator: (value) =>
                        value == null || value.isEmpty ? 'Campo obrigatório' : null,
                      ),
                      TextFormField(
                        controller: _numeroController,
                        decoration: const InputDecoration(labelText: 'Número'),
                        keyboardType: TextInputType.number,
                        readOnly: _modoAtualizacao,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Campo obrigatório';
                          final numero = int.tryParse(value);
                          if (numero == null || numero <= 0) return 'Número inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _salvarCadastro,
                        child: Text(_modoAtualizacao ? 'Atualizar' : 'Salvar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Lista de Cadastros:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: _cadastros.isEmpty
                  ? const Center(child: Text('Nenhum cadastro encontrado.'))
                  : ListView.builder(
                itemCount: _cadastros.length,
                itemBuilder: (context, index) {
                  final item = _cadastros[index];
                  return Center(
                    child: Container(
                      width: 400,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 200,
                                child: Text(
                                  item['texto'],
                                  style: const TextStyle(fontSize: 16, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: Text(
                                  'Número: ${item['numero']}',
                                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () => _editarCadastro(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _confirmarExclusao(item['numero']),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
