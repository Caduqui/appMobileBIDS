import 'package:ensinolinguagens/models/model.dart';
import 'package:ensinolinguagens/models/novo_model.dart';
import 'package:flutter/material.dart';

class ExercicioTela extends StatelessWidget {
  ExercicioTela({super.key});

  final Model model = Model(id: "EX001", name: "Gabriel");
  final List<Palavras> listaPalavras = [
    Palavras(id: "SE001", palavra: "Arara"),
    Palavras(id: "SE002", palavra: "Urubu"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Centro de Educação Especial REME")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print("Foi clicado");
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(onPressed: () {}, child: const Text("Enviar foto")),
            const Text(
              "Como fazer?",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(model.name),
            Divider(),
          ],
        ),
      ),
    );
  }
}
