/// 数据库初始化
library;

import 'package:metamorphosis_checkin/database/database.dart';
import 'package:metamorphosis_checkin/database/check_in_repository.dart';
import 'package:metamorphosis_checkin/database/workout_repository.dart';
import 'package:metamorphosis_checkin/database/measurement_repository.dart';
import 'package:metamorphosis_checkin/database/user_profile_repository.dart';

class DatabaseManager {
  static DatabaseHelper _helper = DatabaseHelper();
  
  static CheckInRepository? _checkInRepository;
  static WorkoutRepository? _workoutRepository;
  static MeasurementRepository? _measurementRepository;
  static UserProfileRepository? _profileRepository;

  static Future<void> init() async {
    final db = await _helper.database;
    _checkInRepository = CheckInRepository(db);
    _workoutRepository = WorkoutRepository(db);
    _measurementRepository = MeasurementRepository(db);
    _profileRepository = UserProfileRepository(db);
  }

  static CheckInRepository get checkInRepository => _checkInRepository!;
  static WorkoutRepository get workoutRepository => _workoutRepository!;
  static MeasurementRepository get measurementRepository => _measurementRepository!;
  static UserProfileRepository get profileRepository => _profileRepository!;

  static Future<void> close() async {
    await _helper.close();
  }
}
