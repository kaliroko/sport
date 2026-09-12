/// 数据库初始化
library;

import 'package:metamorphosis_checkin/database/database.dart';
import 'package:metamorphosis_checkin/database/check_in_repository.dart';
import 'package:metamorphosis_checkin/database/workout_repository.dart';
import 'package:metamorphosis_checkin/database/measurement_repository.dart';
import 'package:metamorphosis_checkin/database/user_profile_repository.dart';
import 'package:metamorphosis_checkin/database/custom_task_repository.dart';
import 'package:metamorphosis_checkin/database/settings_repository.dart';
import 'package:metamorphosis_checkin/database/workout_plan_repository.dart';

class DatabaseManager {
  static CheckInRepository? _checkInRepository;
  static WorkoutRepository? _workoutRepository;
  static MeasurementRepository? _measurementRepository;
  static UserProfileRepository? _profileRepository;
  static CustomTaskRepository? _customTaskRepository;
  static SettingsRepository? _settingsRepository;
  static WorkoutPlanRepository? _workoutPlanRepository;

  static Future<void> init() async {
    final db = await DatabaseHelper.database;
    _checkInRepository = CheckInRepository(db);
    _workoutRepository = WorkoutRepository(db);
    _measurementRepository = MeasurementRepository(db);
    _profileRepository = UserProfileRepository(db);
    _customTaskRepository = CustomTaskRepository(db);
    _settingsRepository = SettingsRepository(db);
    _workoutPlanRepository = WorkoutPlanRepository(db);
  }

  static CheckInRepository get checkInRepository => _checkInRepository!;
  static WorkoutRepository get workoutRepository => _workoutRepository!;
  static MeasurementRepository get measurementRepository => _measurementRepository!;
  static UserProfileRepository get profileRepository => _profileRepository!;
  static CustomTaskRepository get customTaskRepository => _customTaskRepository!;
  static SettingsRepository get settingsRepository => _settingsRepository!;
  static WorkoutPlanRepository get workoutPlanRepository => _workoutPlanRepository!;

  static Future<void> close() async {
    await DatabaseHelper.close();
  }
}
