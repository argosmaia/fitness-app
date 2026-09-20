import 'package:flutter/material.dart';
import '../../auth/domain/auth_models.dart';

final class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key, required this.user});
  final UserProfile? user;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Olá, ${user?.name.split(' ').first ?? 'atleta'}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}',
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(child: Icon(Icons.person)),
              ],
            ),
            const SizedBox(height: 22),
            Card(
              color: const Color(0xFF172126),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 82,
                      height: 82,
                      child: CircularProgressIndicator(
                        value: .72,
                        strokeWidth: 9,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seu dia em equilíbrio',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Complete seus registros para calcular o score diário.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Resumo de hoje',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              children: [
                _Metric(
                  icon: Icons.local_fire_department,
                  label: 'Calorias',
                  value: '0 kcal',
                  color: Color(0xFFF26B38),
                ),
                _Metric(
                  icon: Icons.water_drop,
                  label: 'Água',
                  value: '0 ml',
                  color: Color(0xFF3C9BE8),
                ),
                _Metric(
                  icon: Icons.bedtime,
                  label: 'Sono',
                  value: '—',
                  color: Color(0xFF7559C7),
                ),
                _Metric(
                  icon: Icons.fitness_center,
                  label: 'Treinos',
                  value: '0',
                  color: Color(0xFF42A675),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consistência gera resultado',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Registre pequenas ações ao longo do dia. Quando estiver conectado, seus dados serão sincronizados com segurança.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label),
        ],
      ),
    ),
  );
}
