import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/alterar_senha_page.dart';
import 'package:mobile/app_theme.dart';
import 'package:mobile/editar_perfil_page.dart';
import 'package:mobile/widgets/form_widgets.dart';

/// Abre [pagina] por cima de uma tela inicial e guarda o valor devolvido.
Future<List<Object?>> abrir(WidgetTester tester, Widget pagina) async {
  final resultados = <Object?>[];
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => resultados.add(
              await Navigator.push<Object?>(
                context,
                MaterialPageRoute<Object?>(builder: (_) => pagina),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultados;
}

FilledButton botao(WidgetTester tester, String rotulo) => tester.widget(
  find.ancestor(of: find.text(rotulo), matching: find.byType(FilledButton)),
);

void main() {
  const perfil = EditarPerfilPage(
    nome: 'Maria Silva',
    email: 'maria@exemplo.com',
    telefone: '11912345678',
    endereco: 'Av. Paulista, 1000 - São Paulo',
  );

  group('Editar perfil', () {
    testWidgets('salvar só fica ativo depois de alguma alteração', (
      tester,
    ) async {
      await abrir(tester, perfil);
      expect(botao(tester, 'Salvar alterações').onPressed, isNull);

      await tester.enterText(find.byType(TextFormField).first, 'Maria S.');
      await tester.pump();
      expect(botao(tester, 'Salvar alterações').onPressed, isNotNull);
      expect(find.text('Você tem alterações não salvas'), findsOneWidget);
    });

    testWidgets('devolve os dados editados ao salvar', (tester) async {
      final resultados = await abrir(tester, perfil);
      await tester.enterText(find.byType(TextFormField).first, 'Maria Souza');
      await tester.pump();
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      final dados = resultados.single! as Map;
      expect(dados['nome'], 'Maria Souza');
      expect(dados['telefone'], '(11) 91234-5678');
    });

    testWidgets('e-mail inválido impede salvar e mostra o erro', (
      tester,
    ) async {
      final resultados = await abrir(tester, perfil);
      await tester.enterText(find.byType(TextFormField).at(1), 'maria@');
      await tester.pump();
      await tester.tap(find.text('Salvar alterações'));
      await tester.pumpAndSettle();

      expect(find.text('E-mail inválido'), findsOneWidget);
      expect(resultados, isEmpty);
    });

    testWidgets('pede confirmação ao sair com alterações', (tester) async {
      final resultados = await abrir(tester, perfil);
      await tester.enterText(find.byType(TextFormField).first, 'Outro nome');
      await tester.pump();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('Descartar alterações?'), findsOneWidget);

      await tester.tap(find.text('Descartar'));
      await tester.pumpAndSettle();
      expect(find.byType(EditarPerfilPage), findsNothing);
      expect(resultados.single, isNull);
    });

    test('máscara de telefone', () {
      expect(formatarTelefone('11912345678'), '(11) 91234-5678');
      expect(formatarTelefone('1133334444'), '(11) 3333-4444');
      expect(formatarTelefone('119'), '(11) 9');
    });
  });

  group('Alterar senha', () {
    Future<void> preencher(
      WidgetTester tester, {
      required String nova,
      required String confirmacao,
    }) async {
      final campos = find.byType(TextFormField);
      await tester.enterText(campos.at(0), 'senhaAtual1');
      await tester.enterText(campos.at(1), nova);
      await tester.enterText(campos.at(2), confirmacao);
      await tester.pump();
    }

    testWidgets('botão fica inativo até a senha ser válida e confirmada', (
      tester,
    ) async {
      await abrir(tester, const AlterarSenhaPage());
      expect(botao(tester, 'Atualizar senha').onPressed, isNull);

      await preencher(tester, nova: 'curta', confirmacao: 'curta');
      expect(botao(tester, 'Atualizar senha').onPressed, isNull);

      await preencher(tester, nova: 'NovaSenha#2026', confirmacao: 'Outra');
      expect(botao(tester, 'Atualizar senha').onPressed, isNull);
      expect(find.text('As senhas não coincidem'), findsOneWidget);

      await preencher(
        tester,
        nova: 'NovaSenha#2026',
        confirmacao: 'NovaSenha#2026',
      );
      expect(botao(tester, 'Atualizar senha').onPressed, isNotNull);
      expect(find.text('As senhas coincidem'), findsOneWidget);
    });

    testWidgets('medidor de força acompanha os requisitos', (tester) async {
      await abrir(tester, const AlterarSenhaPage());
      final nova = find.byType(TextFormField).at(1);

      await tester.enterText(nova, 'abcdefgh');
      await tester.pump();
      expect(find.textContaining('Fraca'), findsOneWidget);

      await tester.enterText(nova, 'Abcdefg1!');
      await tester.pump();
      expect(find.textContaining('Forte'), findsOneWidget);
    });
  });
}
