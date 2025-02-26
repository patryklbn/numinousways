import 'package:flutter/material.dart';
import '/models/daymodule.dart';

class DayModuleCard extends StatelessWidget {
  final DayModule module;
  final VoidCallback? onTap;
  final String? heroTag;

  const DayModuleCard({
    Key? key,
    required this.module,
    this.onTap,
    this.heroTag
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(0xFF2E7D32); // Dark green instead of pink

    IconData iconData;
    Color iconColor = Colors.white;

    if (module.isLocked) {
      iconData = Icons.lock_outline;
      iconColor = Colors.grey[200]!;
    } else if (module.isCompleted) {
      iconData = Icons.check_circle_outline;
      iconColor = Colors.white;
    } else {
      iconData = Icons.self_improvement; // Changed to mindfulness icon
      iconColor = Colors.white;
    }

    Widget content = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: module.isLocked ? Colors.grey[300]! : accentColor.withOpacity(0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        image: DecorationImage(
          image: AssetImage('assets/images/myretreat/integration_module.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.2),
            BlendMode.darken,
          ),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.8),
            Color(0xFF1B5E20).withOpacity(0.9), // Darker green
          ],
        ),
      ),
      child: Row(
        children: [
          Icon(iconData, color: iconColor),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModuleHeader(),
                SizedBox(height: 4),
                Text(
                  module.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  module.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        offset: Offset(1, 1),
                        blurRadius: 3,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!module.isLocked)
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.7),
              size: 16,
            ),
        ],
      ),
    );

    if (heroTag != null) {
      content = Hero(tag: heroTag!, child: content);
    }

    return Opacity(
      opacity: module.isLocked ? 0.5 : 1.0,
      child: InkWell(
        onTap: module.isLocked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      ),
    );
  }

  Widget _buildModuleHeader() {
    return Row(
      children: [
        Text(
          "Day ${module.dayNumber}",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black45,
              ),
            ],
          ),
        ),
        if (module.isCompleted) ...[
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Completed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}