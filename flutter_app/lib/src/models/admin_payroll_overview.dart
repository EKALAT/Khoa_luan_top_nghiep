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
    required this.standardWorkUnits,
    required this.totalUsers,
    required this.totalWorkUnits,
    required this.totalPaidWorkUnits,
    required this.totalMonthlySalary,
    required this.totalSalaryAmount,
  });

  final String month;
  final String monthLabel;
  final double standardWorkUnits;
  final int totalUsers;
  final double totalWorkUnits;
  final double totalPaidWorkUnits;
  final double totalMonthlySalary;
  final double totalSalaryAmount;

  factory AdminPayrollSummary.fromJson(Map<String, dynamic> json) {
    return AdminPayrollSummary(
      month: asString(json['month']) ?? '',
      monthLabel: asString(json['month_label']) ?? '',
      standardWorkUnits: asDouble(json['standard_work_units']) ?? 25,
      totalUsers: asInt(json['total_users']) ?? 0,
      totalWorkUnits: asDouble(json['total_work_units']) ?? 0,
      totalPaidWorkUnits: asDouble(json['total_paid_work_units']) ?? 0,
      totalMonthlySalary: asDouble(json['total_monthly_salary']) ?? 0,
      totalSalaryAmount: asDouble(json['total_salary_amount']) ?? 0,
    );
  }
}
