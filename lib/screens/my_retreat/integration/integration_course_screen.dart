import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '/models/daymodule.dart';
import '/viewmodels/integration_provider.dart';
import '/widgets/integration/daymodule_card.dart';

class IntegrationCourseScreen extends StatefulWidget {
  @override
  _IntegrationCourseScreenState createState() => _IntegrationCourseScreenState();
}

class _IntegrationCourseScreenState extends State<IntegrationCourseScreen> with SingleTickerProviderStateMixin {
  final Color _primaryColor = const Color(0xFF1B4332);
  final Color _secondaryColor = const Color(0xFF2D6A4F);
  final Color _accentColor = const Color(0xFF40916C);
  final Color _backgroundColor = const Color(0xFFF0F7F4);
  final Color _cardColor = Colors.white;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IntegrationProvider>().loadData();
    });
  }

  bool isModuleUnlocked(IntegrationProvider provider, DayModule module) {
    if (provider.userStartDate == null) return false;
    if (module.dayNumber == 1) return true;

    final today = DateTime.now();
    final daysSinceStart = today.difference(provider.userStartDate!).inDays;
    return module.dayNumber <= daysSinceStart + 1; // +1 to include current day
  }

  Widget _buildModuleCard(DayModule module, IntegrationProvider integrationVM) {
    final isUnlocked = isModuleUnlocked(integrationVM, module);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onModuleTap(integrationVM, module),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: _primaryColor.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DayModuleCard(
            module: module.copyWith(isLocked: !isUnlocked),
            onTap: () => _onModuleTap(integrationVM, module),
            heroTag: 'integration_day_${module.dayNumber}',
          ),
        ),
      ),
    );
  }

  Future<void> _onModuleTap(IntegrationProvider integrationVM, DayModule module) async {
    final isUnlocked = isModuleUnlocked(integrationVM, module);

    if (!isUnlocked) {
      final daysUntilUnlock = module.dayNumber - 1;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('This module will unlock in $daysUntilUnlock days'),
          backgroundColor: _primaryColor,
        ),
      );
      return;
    }

    final result = await Navigator.pushNamed(
      context,
      '/integration_day_detail',
      arguments: {
        'dayNumber': module.dayNumber,
        'isDayCompleted': module.isCompleted,
      },
    );

    if (result == true) {
      await integrationVM.markModuleCompleted(module.dayNumber);
    }
  }

  Widget _buildHeroHeader(Color accentColor) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
        height: 250.0,
        color: accentColor,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/myretreat/integration.png',
              fit: BoxFit.cover,
            ),
            Container(color: Colors.black.withOpacity(0.3)),
            Positioned(
              top: 40,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Text(
                "21 Day Integration",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 4.0,
                      color: Colors.black54,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(IntegrationProvider integrationVM) {
    return ElevatedButton(
      onPressed: () async {
        final now = DateTime.now();
        await integrationVM.setUserStartDate(now);
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: _accentColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 14,
        ),
        elevation: 4,
      ),
      child: const Text(
        'Start Course',
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final integrationVM = context.watch<IntegrationProvider>();

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: RefreshIndicator(
        color: _accentColor,
        onRefresh: () => integrationVM.loadData(),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Enhanced Hero Header
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildHeroHeader(_accentColor),
                  if (integrationVM.userStartDate == null &&
                      !integrationVM.hasUserClickedStart)
                    Positioned(
                      bottom: -30,
                      right: 20,
                      child: _buildStartButton(integrationVM),
                    ),
                ],
              ),
            ),

            // Main Content
            SliverToBoxAdapter(
              child: AnimatedPadding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  (integrationVM.userStartDate == null &&
                      !integrationVM.hasUserClickedStart)
                      ? 50
                      : 20,
                  20,
                  20,
                ),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: _buildBodyContent(integrationVM),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(IntegrationProvider integrationVM) {
    if (integrationVM.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (integrationVM.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[300], size: 48),
            const SizedBox(height: 16),
            Text(
              'Error: ${integrationVM.errorMessage}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final modules = integrationVM.allModules;
    final userStartDate = integrationVM.userStartDate;

    final completedCount = modules.where((m) => m.isCompleted).length;
    const totalModules = 21;
    final progressValue = completedCount / totalModules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Continue Your Growth",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),

        Text(
          "Your 21-day integration journey helps you process and integrate your experiences. "
              "Through mindfulness practices, journaling, and community support, "
              "we'll help you maintain the insights and growth from your retreat.",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.6,
            color: _primaryColor.withOpacity(0.8),
          ),
        ),

        const SizedBox(height: 32),

        if (userStartDate != null) ...[
          _buildProgressSection(progressValue, completedCount),
          const SizedBox(height: 16),
        ],

        Column(
          children: modules.map((module) {
            final isLast = module == modules.last;
            final isUnlocked = isModuleUnlocked(integrationVM, module);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 40,
                  child: Column(
                    children: [
                      if (module != modules.first)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey[400],
                        ),
                      Icon(
                        module.isCompleted ? Icons.check_circle_outline :
                        (isUnlocked ? Icons.lock_open_outlined : Icons.lock),
                        color: module.isCompleted ? Colors.green :
                        (isUnlocked ? _accentColor : Colors.grey),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 20,
                          color: Colors.grey[400],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 400 + (modules.indexOf(module) * 100)),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 50 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: _buildModuleCard(module, integrationVM),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildProgressSection(double progressValue, int completedCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: _primaryColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "$completedCount/21 days completed",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _primaryColor,
              ),
            ),
            Text(
              "${(progressValue * 100).toInt()}% complete",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _accentColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}