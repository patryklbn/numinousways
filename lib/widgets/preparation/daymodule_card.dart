import 'package:flutter/material.dart';
import '/models/daymodule.dart';

class DayModuleCard extends StatelessWidget {
  final DayModule module;
  final VoidCallback? onTap;
  final String? heroTag;

  const DayModuleCard({Key? key, required this.module, this.onTap, this.heroTag}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accentColor = Color(0xFFB4347F);

    IconData iconData;
    Color iconColor = Colors.white;

    if (module.isLocked) {
      iconData = Icons.lock_outline;
      iconColor = Colors.grey[200]!;
    } else if (module.isCompleted) {
      iconData = Icons.check_circle_outline;
      iconColor = Colors.white;
    } else {
      iconData = Icons.lock_open_outlined;
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
          image: AssetImage('assets/images/myretreat/daymodule.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.2),
            BlendMode.darken,
          ),
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
              ],
            ),
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
        child: content,
      ),
    );
  }

  /// If dayNumber=0 => "Day 0" => maybe show "Before PPS"
  /// If dayNumber=22 => "Day 22" => maybe show "After PPS"
  /// else => "Day X"
  Widget _buildModuleHeader() {
    String dayLabel;
    if (module.dayNumber == 0) {
      dayLabel = "Day 0";
    } else if (module.dayNumber == 22) {
      dayLabel = "Day 22";
    } else {
      dayLabel = "Day ${module.dayNumber}";
    }

    return Text(
      dayLabel,
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
    );
  }
}
