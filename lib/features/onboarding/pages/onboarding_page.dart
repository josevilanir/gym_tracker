// lib/features/onboarding/pages/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingPage({super.key, required this.onComplete});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      icon: Icons.fitness_center,
      title: 'Bem-vindo ao Gym Tracker',
      description:
          'Organize seus treinos de forma simples e eficiente. Todos os seus dados ficam salvos localmente no seu dispositivo.',
      color: Colors.blue,
    ),
    OnboardingStep(
      icon: Icons.library_books,
      title: 'Crie Rotinas',
      description:
          'Monte rotinas de treino com seus exercícios favoritos. Reutilize-as sempre que quiser para economizar tempo!',
      color: Colors.purple,
    ),
    OnboardingStep(
      icon: Icons.play_circle_outline,
      title: 'Inicie Treinos',
      description:
          'Comece um treino a partir de uma rotina salva ou crie do zero. Registre séries, repetições e peso em tempo real.',
      color: Colors.orange,
    ),
    OnboardingStep(
      icon: Icons.show_chart,
      title: 'Acompanhe seu Progresso',
      description:
          'Visualize seu histórico completo, gráficos de volume e estatísticas de evolução. Tudo offline!',
      color: Colors.green,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    widget.onComplete();
  }

  void _skip() {
    _pageController.animateToPage(
      _steps.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Botão Skip
            if (_currentPage < _steps.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: _skip,
                    child: const Text('Pular'),
                  ),
                ),
              )
            else
              const SizedBox(height: 60),

            // Conteúdo das páginas
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _steps.length,
                itemBuilder: (context, index) {
                  return _OnboardingStepWidget(step: _steps[index]);
                },
              ),
            ),

            // Indicadores e botões
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Indicadores de página
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? _steps[_currentPage].color
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botões de navegação
                  Row(
                    children: [
                      if (_currentPage > 0)
                        TextButton.icon(
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Voltar'),
                        ),
                      const Spacer(),
                      if (_currentPage < _steps.length - 1)
                        FilledButton.icon(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Próximo'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _steps[_currentPage].color,
                          ),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _complete,
                          icon: const Icon(Icons.check),
                          label: const Text('Começar'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _steps[_currentPage].color,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStepWidget extends StatelessWidget {
  final OnboardingStep step;

  const _OnboardingStepWidget({required this.step});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone animado
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: step.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step.icon,
                    size: 80,
                    color: step.color,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 48),

          // Título
          Text(
            step.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: step.color,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Descrição
          Text(
            step.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OnboardingStep {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}