// In frontend/lib/features/manager_dashboard/domain/usecases/get_weekly_menu.dart
import 'package:mess_management_system/features/manager_dashboard/domain/entities/weekly_menu.dart';
import 'package:mess_management_system/features/manager_dashboard/domain/repositories/manager_repository.dart';

class GetWeeklyMenu {
  final ManagerRepository repository;
  GetWeeklyMenu(this.repository);
  Future<WeeklyMenu> call() => repository.getWeeklyMenu();
}
