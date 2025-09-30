import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/miru_task.dart';

class StorageService {
  static const String _tasksKey = 'miru_tasks';
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // 모든 미루기 작업 저장
  Future<void> saveTasks(List<MiruTask> tasks) async {
    final tasksJson = tasks.map((task) => task.toJson()).toList();
    final tasksString = jsonEncode(tasksJson);
    await _prefs!.setString(_tasksKey, tasksString);
  }

  // 모든 미루기 작업 불러오기
  Future<List<MiruTask>> getTasks() async {
    final tasksString = _prefs!.getString(_tasksKey);
    if (tasksString == null) {
      return [];
    }

    try {
      final List<dynamic> tasksJson = jsonDecode(tasksString);
      return tasksJson.map((json) => MiruTask.fromJson(json)).toList();
    } catch (e) {
      print('Error loading tasks: $e');
      return [];
    }
  }

  // 새로운 미루기 작업 추가
  Future<void> addTask(MiruTask task) async {
    final tasks = await getTasks();
    tasks.add(task);
    await saveTasks(tasks);
  }

  // 미루기 작업 삭제
  Future<void> deleteTask(String taskId) async {
    final tasks = await getTasks();
    tasks.removeWhere((task) => task.id == taskId);
    await saveTasks(tasks);
  }

  // 미루기 작업 업데이트
  Future<void> updateTask(MiruTask updatedTask) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((task) => task.id == updatedTask.id);
    if (index != -1) {
      tasks[index] = updatedTask;
      await saveTasks(tasks);
    }
  }

  // 완료된 작업만 삭제
  Future<void> clearCompletedTasks() async {
    final tasks = await getTasks();
    final incompleteTasks = tasks.where((task) => !task.isCompleted).toList();
    await saveTasks(incompleteTasks);
  }

  // 모든 데이터 삭제
  Future<void> clearAllTasks() async {
    await _prefs!.remove(_tasksKey);
  }
}
