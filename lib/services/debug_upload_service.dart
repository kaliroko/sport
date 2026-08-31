/// 调试上传服务 - 上传运动数据及设备信息到远程服务器
library;

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:metamorphosis_checkin/database/app_database.dart';
import 'package:metamorphosis_checkin/models/daily_check_in.dart';
import 'package:metamorphosis_checkin/models/workout_log.dart';
import 'package:metamorphosis_checkin/models/user_profile.dart';
import 'package:metamorphosis_checkin/models/body_measurement.dart';

class DebugUploadService extends ChangeNotifier {
  static const String _defaultServerUrl =
      'http://192.168.1.100:8080/api/debug/upload';

  String _serverUrl = _defaultServerUrl;
  String _lastStatus = '未连接';
  bool _isUploading = false;
  int _lastUploadCount = 0;
  DateTime? _lastUploadTime;

  String get serverUrl => _serverUrl;
  String get lastStatus => _lastStatus;
  bool get isUploading => _isUploading;
  int get lastUploadCount => _lastUploadCount;
  DateTime? get lastUploadTime => _lastUploadTime;

  /// 设置服务器地址
  void setServerUrl(String url) {
    _serverUrl = url;
    notifyListeners();
  }

  /// 获取设备信息（无需额外依赖）
  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final info = <String, dynamic>{
      'platform': defaultTargetPlatform.name,
      'os': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
      'cpuCount': Platform.numberOfProcessors,
    };

    if (Platform.isAndroid) {
      info.addAll({
        'model': Platform.localeName,
        'androidVersion': Platform.version,
      });
    }

    return info;
  }

  /// 收集所有本地数据
  Future<Map<String, dynamic>> _collectLocalData() async {
    final data = <String, dynamic>{};

    // 收集打卡数据
    try {
      final checkIns = await DatabaseManager.checkInRepository.getRecentCheckIns(30);
      data['check_ins'] = checkIns.map((c) => c.toMap()).toList();
      data['check_in_count'] = checkIns.length;
    } catch (e) {
      data['check_ins_error'] = e.toString();
    }

    // 收集运动数据
    try {
      final workouts = await DatabaseManager.workoutRepository.getRecentWorkoutLogs(30);
      data['workouts'] = workouts.map((w) => w.toMap()).toList();
      data['workout_count'] = workouts.length;
    } catch (e) {
      data['workout_error'] = e.toString();
    }

    // 收集用户资料
    try {
      final profile = await DatabaseManager.profileRepository.getProfile();
      if (profile != null) {
        data['profile'] = profile.toMap();
      }
    } catch (e) {
      data['profile_error'] = e.toString();
    }

    // 收集身体测量数据
    try {
      final measurements = await DatabaseManager.measurementRepository.getAllMeasurements();
      data['measurements'] = measurements.map((m) => m.toMap()).toList();
      data['measurement_count'] = measurements.length;
    } catch (e) {
      data['measurement_error'] = e.toString();
    }

    return data;
  }

  /// 上传数据到远程服务器
  Future<UploadResult> uploadData() async {
    _isUploading = true;
    _lastStatus = '上传中...';
    notifyListeners();

    try {
      final deviceInfo = await _getDeviceInfo();
      final localData = await _collectLocalData();

      final payload = {
        'timestamp': DateTime.now().toIso8601String(),
        'device': deviceInfo,
        'data': localData,
        'app_version': '1.0.0',
        'app_name': '自律',
      };

      _lastStatus = '正在连接: ${_serverUrl}';
      notifyListeners();

      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _lastStatus = '上传成功 (${response.statusCode})';
        final checkInCount = localData['check_in_count'] as int? ?? 0;
        final workoutCount = localData['workout_count'] as int? ?? 0;
        _lastUploadCount = checkInCount + workoutCount;
        _lastUploadTime = DateTime.now();
        notifyListeners();
        return UploadResult.success(_lastUploadCount);
      } else {
        _lastStatus = '服务器错误: ${response.statusCode}';
        notifyListeners();
        return UploadResult.failure('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      _lastStatus = '上传失败: $e';
      notifyListeners();
      return UploadResult.failure(e.toString());
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// 仅上传运动数据
  Future<UploadResult> uploadWorkoutData() async {
    _isUploading = true;
    _lastStatus = '上传运动数据中...';
    notifyListeners();

    try {
      final workouts = await DatabaseManager.workoutRepository.getRecentWorkoutLogs(7);
      final payload = {
        'type': 'workout_data',
        'timestamp': DateTime.now().toIso8601String(),
        'count': workouts.length,
        'logs': workouts.map((w) => w.toMap()).toList(),
      };

      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _lastStatus = '运动数据上传成功 (${workouts.length}条)';
        _lastUploadCount = workouts.length;
        _lastUploadTime = DateTime.now();
        notifyListeners();
        return UploadResult.success(workouts.length);
      } else {
        _lastStatus = '服务器错误: ${response.statusCode}';
        notifyListeners();
        return UploadResult.failure('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _lastStatus = '上传失败: $e';
      notifyListeners();
      return UploadResult.failure(e.toString());
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// 仅上传打卡数据
  Future<UploadResult> uploadCheckInData() async {
    _isUploading = true;
    _lastStatus = '上传打卡数据中...';
    notifyListeners();

    try {
      final checkIns = await DatabaseManager.checkInRepository.getRecentCheckIns(7);
      final payload = {
        'type': 'check_in_data',
        'timestamp': DateTime.now().toIso8601String(),
        'count': checkIns.length,
        'records': checkIns.map((c) => c.toMap()).toList(),
      };

      final response = await http.post(
        Uri.parse(_serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        _lastStatus = '打卡数据上传成功 (${checkIns.length}条)';
        _lastUploadCount = checkIns.length;
        _lastUploadTime = DateTime.now();
        notifyListeners();
        return UploadResult.success(checkIns.length);
      } else {
        _lastStatus = '服务器错误: ${response.statusCode}';
        notifyListeners();
        return UploadResult.failure('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _lastStatus = '上传失败: $e';
      notifyListeners();
      return UploadResult.failure(e.toString());
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// 测试连接
  Future<String> testConnection() async {
    _lastStatus = '测试连接中...';
    notifyListeners();

    try {
      final response = await http.get(Uri.parse(_serverUrl)).timeout(const Duration(seconds: 10));
      _lastStatus = '连接测试: ${response.statusCode} ${response.body.isEmpty ? '(无响应体)' : response.body}';
      notifyListeners();
      return _lastStatus;
    } catch (e) {
      _lastStatus = '连接失败: $e';
      notifyListeners();
      return _lastStatus;
    }
  }

  /// 清除状态
  void clearStatus() {
    _lastStatus = '就绪';
    notifyListeners();
  }
}

class UploadResult {
  final bool success;
  final int? recordsCount;
  final String error;

  const UploadResult._(this.success, this.recordsCount, this.error);

  factory UploadResult.success(int count) =>
      UploadResult._(true, count, '');

  factory UploadResult.failure(String message) =>
      const UploadResult._(false, null, '');
}