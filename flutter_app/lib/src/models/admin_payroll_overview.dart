import '../core/utils/json_utils.dart';
import 'admin_payroll_user.dart';
import 'paginated_response.dart';

class AdminPayrollOverview {
  const AdminPayrollOverview({
    required this.page,
    required this.summary,
  });

  final PaginatedResponse<AdminPayrollUser> page;
  final AdminPayrollSummary summary;

  factory AdminPayrollOverview.fromJson(Map<String, dynamic> json) {
    return AdminPayrollOverview(
      page: PaginatedResponse<AdminPayrollUser>.fromJson(
        json,
        AdminPayrollUser.fromJson,
      ),
      summary: AdminPayrollSummary.fromJson(asMap(json['summary'])),
    );
  }
}

class AdminPayrollSummary {
  const AdminPayrollSummary({
    required this.month,
    required this.monthLabel,
    this.rangeEnd,
    required this.standardWorkDays,
    required this.totalUsers,
    required this.totalWorkUnits,
    required this.totalNetSalary,
    required this.fullSalaryEmployeeCount,
    required this.withoutSalaryConfigCount,
  });

  final String month;
  final String monthLabel;
  final String? rangeEnd;
  final double standardWorkDays;
  final int totalUsers;
  final double totalWorkUnits;
  final double totalNetSalary;
  final int fullSalaryEmployeeCount;
  final int withoutSalaryConfigCount;

  factory AdminPayrollSummary.fromJson(Map<String, dynamic> json) {
    return AdminPayrollSummary(
      month: asString(json['month']) ?? '',
      monthLabel: asString(json['month_label']) ?? '',
      rangeEnd: asString(json['range_end']),
      standardWorkDays: asDouble(json['standard_work_days']) ?? 25,
      totalUsers: asInt(json['total_users']) ?? 0,
      totalWorkUnits: asDouble(json['total_work_units']) ?? 0,
      totalNetSalary: asDouble(json['total_net_salary']) ?? 0,
      fullSalaryEmployeeCount: asInt(json['full_salary_employee_count']) ?? 0,
      withoutSalaryConfigCount: asInt(json['without_salary_config_count']) ?? 0,
    );
  }
}
