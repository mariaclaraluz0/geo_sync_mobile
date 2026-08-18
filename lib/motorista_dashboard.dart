import 'package:flutter/material.dart';
import 'package:mobile/login_screen.dart';

class MotoristaDashboard extends StatefulWidget {
  const MotoristaDashboard({super.key});

  @override
  State<MotoristaDashboard> createState() =>
      _MotoristaDashboardState();
}

class _MotoristaDashboardState
    extends State<MotoristaDashboard> {
  static const Color _primary = Color(0xFF0C46FF);

  int _paginaAtual = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          theme.scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor:
            theme.scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,

        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'GeoSync',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            Text(
              'Área do motorista',
              style: TextStyle(
                color: theme
                    .colorScheme
                    .onSurface
                    .withOpacity(0.55),
                fontSize: 12,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Notificações',
            onPressed: () {
              _mostrarMensagem(
                'Você não possui novos avisos.',
              );
            },
            icon: Badge(
              label: const Text('1'),
              child: Icon(
                Icons.notifications_none_rounded,
                color: theme.colorScheme.onSurface
                    .withOpacity(0.7),
              ),
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      body: IndexedStack(
        index: _paginaAtual,
        children: [
          _inicio(),
          _minhasEntregas(),
          _meusGanhos(),
          _perfil(),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _paginaAtual,

        onDestinationSelected: (index) {
          setState(() {
            _paginaAtual = index;
          });
        },

        indicatorColor:
            _primary.withOpacity(
          isDark ? 0.22 : 0.14,
        ),

        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
            ),
            label: 'Início',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.local_shipping_outlined,
            ),
            selectedIcon: Icon(
              Icons.local_shipping,
            ),
            label: 'Entregas',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.account_balance_wallet_outlined,
            ),
            selectedIcon: Icon(
              Icons.account_balance_wallet,
            ),
            label: 'Ganhos',
          ),

          NavigationDestination(
            icon: Icon(
              Icons.person_outline,
            ),
            selectedIcon: Icon(
              Icons.person,
            ),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INÍCIO
  // ============================================================

  Widget _inicio() {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        28,
      ),
      children: [
        Text(
          'Olá, Carlos 👋',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface
                .withOpacity(0.60),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'Sua rota de hoje',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 18),

        _cardRota(),

        const SizedBox(height: 22),

        Text(
          'Resumo do dia',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _resumo(
                Icons.inventory_2_outlined,
                '3',
                'entregas',
                _primary,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _resumo(
                Icons.route_outlined,
                '186 km',
                'percorridos',
                const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        Text(
          'Próximas paradas',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 12),

        _parada(
          '1',
          'Centro de Distribuição',
          'Retirada confirmada • 09:30',
          Icons.inventory_2_rounded,
        ),

        _parada(
          '2',
          'Av. Paulista, 1578',
          'Entrega prevista • 11:40',
          Icons.location_on_rounded,
        ),

        _parada(
          '3',
          'Rua das Flores, 82',
          'Entrega prevista • 14:20',
          Icons.location_on_rounded,
        ),
      ],
    );
  }

  // ============================================================
  // CARD DA ROTA
  // ============================================================

  Widget _cardRota() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0B2A4A),
            _primary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.navigation_rounded,
                color: Colors.white,
              ),

              SizedBox(width: 8),

              Text(
                'VIAGEM EM ANDAMENTO',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            'GS-9532',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'São Paulo, SP  →  Rio de Janeiro, RJ',
            style: TextStyle(
              color: Colors.white70,
            ),
          ),

          const SizedBox(height: 18),

          ElevatedButton.icon(
            onPressed: () {
              _mostrarMensagem(
                'Navegação para a próxima parada iniciada.',
              );
            },

            icon: const Icon(
              Icons.directions,
            ),

            label: const Text(
              'Abrir navegação',
            ),

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: _primary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESUMO
  // ============================================================

  Widget _resumo(
    IconData icon,
    String valor,
    String legenda,
    Color cor,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: cor,
          ),

          const SizedBox(height: 14),

          Text(
            valor,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),

          Text(
            legenda,
            style: TextStyle(
              color: theme.colorScheme.onSurface
                  .withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PARADA
  // ============================================================

  Widget _parada(
    String numero,
    String titulo,
    String detalhe,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 4,
      ),

      leading: CircleAvatar(
        backgroundColor:
            _primary.withOpacity(0.1),

        foregroundColor: _primary,

        child: Text(
          numero,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      title: Text(
        titulo,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),

      subtitle: Text(
        detalhe,
        style: TextStyle(
          color: theme.colorScheme.onSurface
              .withOpacity(0.55),
        ),
      ),

      trailing: Icon(
        icon,
        color: _primary,
      ),
    );
  }

  // ============================================================
  // MINHAS ENTREGAS
  // ============================================================

  Widget _minhasEntregas() {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),

      children: [
        Text(
          'Minhas entregas',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Somente cargas atribuídas a você.',
          style: TextStyle(
            color: theme.colorScheme.onSurface
                .withOpacity(0.55),
          ),
        ),

        const SizedBox(height: 18),

        _entrega(
          'GS-9532',
          'São Paulo → Rio de Janeiro',
          'Em rota',
          const Color(0xFF2563EB),
        ),

        _entrega(
          'GS-6548',
          'Uberlândia → Pelotas',
          'Aguardando coleta',
          const Color(0xFFF59E0B),
        ),

        _entrega(
          'GS-1705',
          'Curitiba → Belo Horizonte',
          'Entregue',
          const Color(0xFF16A34A),
        ),
      ],
    );
  }

  // ============================================================
  // ENTREGA
  // ============================================================

  Widget _entrega(
    String codigo,
    String rota,
    String status,
    Color cor,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,

      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),

        side: BorderSide(
          color: theme.dividerColor
              .withOpacity(0.6),
        ),
      ),

      child: ListTile(
        contentPadding:
            const EdgeInsets.all(16),

        leading: Container(
          padding: const EdgeInsets.all(10),

          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius:
                BorderRadius.circular(12),
          ),

          child: Icon(
            Icons.local_shipping_rounded,
            color: cor,
          ),
        ),

        title: Text(
          codigo,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),

        subtitle: Text(
          rota,
          style: TextStyle(
            color: theme.colorScheme.onSurface
                .withOpacity(0.55),
          ),
        ),

        trailing: Text(
          status,
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),

        onTap: () {
          _mostrarMensagem(
            'Detalhes de $codigo abertos.',
          );
        },
      ),
    );
  }

  // ============================================================
  // MEUS GANHOS
  // ============================================================

  Widget _meusGanhos() {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),

      children: [
        Text(
          'Meus ganhos',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(22),

          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(22),
          ),

          child: const Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'DISPONÍVEL ESTA SEMANA',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'R\$ 1.480,00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),

              SizedBox(height: 4),

              Text(
                '6 entregas concluídas',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Últimos repasses',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.onSurface,
          ),
        ),

        const SizedBox(height: 8),

        ListTile(
          title: Text(
            'Entrega GS-1705',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Text(
            'R\$240,00',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ListTile(
          title: Text(
            'Entrega GS-8122',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Text(
            'R\$310,00',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PERFIL
  // ============================================================

  Widget _perfil() {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),

      children: [
        const Center(
          child: CircleAvatar(
            radius: 42,
            backgroundColor: Color(0xFFE9EEFF),
            child: Icon(
              Icons.person,
              size: 46,
              color: _primary,
            ),
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: Text(
            'Carlos Silva',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),

        Center(
          child: Text(
            'Motorista • CNH válida',
            style: TextStyle(
              color: theme.colorScheme.onSurface
                  .withOpacity(0.55),
            ),
          ),
        ),

        const SizedBox(height: 24),

        ListTile(
          leading: Icon(
            Icons.badge_outlined,
            color: theme.colorScheme.onSurface,
          ),
          title: Text(
            'Documentos',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'CNH e dados do veículo',
            style: TextStyle(
              color: theme.colorScheme.onSurface
                  .withOpacity(0.55),
            ),
          ),
        ),

        ListTile(
          leading: Icon(
            Icons.directions_car_outlined,
            color: theme.colorScheme.onSurface,
          ),
          title: Text(
            'Meu veículo',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: Text(
            'Volvo VM 270 • ABC-1D23',
            style: TextStyle(
              color: theme.colorScheme.onSurface
                  .withOpacity(0.55),
            ),
          ),
        ),

        Divider(
          color: theme.dividerColor,
        ),

        ListTile(
          leading: const Icon(
            Icons.logout,
            color: Colors.red,
          ),
          title: const Text(
            'Sair da conta',
            style: TextStyle(
              color: Colors.red,
            ),
          ),
          onTap: _sair,
        ),
      ],
    );
  }

  // ============================================================
  // MENSAGEM
  // ============================================================

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(mensagem),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // SAIR
  // ============================================================

  void _sair() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }
}