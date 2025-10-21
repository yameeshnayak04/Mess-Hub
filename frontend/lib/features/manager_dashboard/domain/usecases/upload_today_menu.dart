// lib/features/manager_dashboard/domain/usecases/upload_today_menu.dart

import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class UploadTodayMenu {
  final ManagerRepository repository;

  UploadTodayMenu(this.repository);

  Future<void> call(Map<String, dynamic> menuData) {
    return repository.uploadTodayMenu(menuData);
  }
}
