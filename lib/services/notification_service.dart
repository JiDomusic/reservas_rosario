// Notification Service - disabled for local-only mode.
// Re-enable with audioplayers + vibration when needed.

import 'package:flutter/material.dart';

class NotificationService {
  static void initialize(BuildContext context) {}
  static void dispose() {}
  static void showNotification(BuildContext context, String message) {}
}
