import 'package:flutter/material.dart';
import 'package:mobile/services/api_exception.dart';
import 'package:mobile/services/api_service.dart';

class CarteiraPage extends StatefulWidget {
  const CarteiraPage({super.key});

  @override
  State<CarteiraPage> createState() => _CarteiraPageState();
}

class _CarteiraPageState extends State<CarteiraPage> {
  bool _carregando = true;
  String? _erro;
  List<Map<String, dynamic>> _pagamentos = [];

  @override
  void initState() {
    super.initState();
    _carregarPagamentos();
  }

  Future<void> _carregarPagamentos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final resposta = await ApiService.instance.pagamentos(
        forceRefresh: _pagamentos.isNotEmpty,
      );
      if (!mounted) return;
      setState(() {
        _pagamentos = resposta.whereType<Map>().map((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
        _carregando = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.message;
        _carregando = false;
      });
    }
  }

  double get _total => _pagamentos.fold(0, (total, pagamento) {
    final valor = double.tryParse('${pagamento['valor'] ?? 0}') ?? 0;
    return total + valor;
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carteira'),
        actions: [
          IconButton(
            tooltip: 'Atualizar carteira',
            onPressed: _carregando ? null : _carregarPagamentos,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _carregarPagamentos,
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth > 600 ? 28 : 16,
                  vertical: 20,
                ),
                children: [
                  _saldoCard(scheme),
                  const SizedBox(height: 24),
                  Text(
                    'Movimentações',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_carregando)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_erro != null)
                    _estadoErro()
                  else if (_pagamentos.isEmpty)
                    _estadoVazio()
                  else
                    ..._pagamentos.map(_pagamentoCard),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _saldoCard(ColorScheme scheme) {
    return Semantics(
      label:
          'Resumo da carteira. Total movimentado ${_total.toStringAsFixed(2)} reais.',
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, scheme.primaryContainer],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              color: scheme.onPrimary,
              size: 30,
            ),
            const SizedBox(height: 18),
            Text(
              'Total movimentado',
              style: TextStyle(color: scheme.onPrimary.withValues(alpha: .85)),
            ),
            const SizedBox(height: 4),
            Text(
              'R\$ ${_total.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                color: scheme.onPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pagamentoCard(Map<String, dynamic> pagamento) {
    final scheme = Theme.of(context).colorScheme;
    final valor = '${pagamento['valor'] ?? '0,00'}';
    final status = '${pagamento['status'] ?? 'Processando'}';
    final descricao =
        '${pagamento['descricao'] ?? pagamento['tipo'] ?? 'Pagamento'}';
    return Semantics(
      label: '$descricao, valor $valor reais, status $status',
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 5,
          ),
          leading: CircleAvatar(
            backgroundColor: scheme.primaryContainer,
            child: Icon(Icons.receipt_long_rounded, color: scheme.primary),
          ),
          title: Text(
            descricao,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(status),
          trailing: Text(
            'R\$ $valor',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }

  Widget _estadoErro() => _mensagemEstado(
    Icons.cloud_off_rounded,
    _erro!,
    'Tentar novamente',
    _carregarPagamentos,
  );

  Widget _estadoVazio() => _mensagemEstado(
    Icons.account_balance_wallet_outlined,
    'Nenhuma movimentação encontrada.',
    null,
    null,
  );

  Widget _mensagemEstado(
    IconData icon,
    String mensagem,
    String? acao,
    VoidCallback? onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 18),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(mensagem, textAlign: TextAlign.center),
          if (acao != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onPressed, child: Text(acao)),
          ],
        ],
      ),
    );
  }
}
