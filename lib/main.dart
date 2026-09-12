import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:metamorphosis_checkin/app.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:metamorphosis_checkin/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();
  await DatabaseManager.init();
  await NotificationService().init();
  runApp(const MetamorphosisApp());
}