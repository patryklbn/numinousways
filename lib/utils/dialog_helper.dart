import 'package:flutter/material.dart';

class DialogHelper {
  static Future<void> showErrorDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Oops! Something went wrong",
                style: TextStyle(color: Colors.red),
                overflow: TextOverflow.ellipsis, // To handle any extra long text
                maxLines: 2, // Allows up to two lines if neededpatry
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  static Future<void> showSuccessDialog(BuildContext context, String message) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "Success!",
                style: TextStyle(color: Colors.green),
              ),
            ),
          ],
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }
}
