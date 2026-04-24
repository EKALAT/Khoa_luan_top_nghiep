<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRecord;
use App\Models\Department;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AdminPayrollController extends Controller
{
    private const STANDARD_WORK_UNITS = 25.0;

    public function overview(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'month' => ['nullable', 'date_format:Y-m'],
            'department_id' => ['nullable', 'integer', 'exists:departments,id'],
            'search' => ['nullable', 'string', 'max:100'],
        ]);

        $selectedMonth = isset($filters['month'])
            ? Carbon::createFromFormat('Y-m', $filters['month'])->startOfMonth()
            : now()->startOfMonth();

        $rangeStart = $selectedMonth->copy()->startOfMonth();
        $rangeEnd = $selectedMonth->copy()->endOfMonth();

        $baseQuery = $this->buildBaseUserQuery($filters);
        $summaryUsers = (clone $baseQuery)->get();
        $paginator = (clone $baseQuery)
            ->orderBy('users.name')
            ->paginate(10)
            ->appends($request->query());

        $allRecordsByUser = $this->fetchMonthlyRecordsForUsers(
            $summaryUsers->pluck('id'),
            $rangeStart,
            $rangeEnd
        );

        $pageRecordsByUser = $this->fetchMonthlyRecordsForUsers(
            $paginator->getCollection()->pluck('id'),
            $rangeStart,
            $rangeEnd
        );

        $summary = $this->buildPayrollSummary(
            users: $summaryUsers,
            monthlyRecordsByUser: $allRecordsByUser,
            selectedMonth: $selectedMonth
        );

        $paginator->setCollection(
            $paginator->getCollection()->map(
                fn (User $user) => $this->transformPayrollUser(
                    request: $request,
                    user: $user,
                    monthlyRecords: $pageRecordsByUser->get($user->id, collect())
                )
            )
        );

        return response()->json([
            ...$paginator->toArray(),
            'summary' => $summary,
        ]);
    }

    public function exportCsv(Request $request): StreamedResponse
    {
        $filters = $request->validate([
            'month' => ['nullable', 'date_format:Y-m'],
            'department_id' => ['nullable', 'integer', 'exists:departments,id'],
            'search' => ['nullable', 'string', 'max:100'],
        ]);

        $selectedMonth = isset($filters['month'])
            ? Carbon::createFromFormat('Y-m', $filters['month'])->startOfMonth()
            : now()->startOfMonth();

        $rangeStart = $selectedMonth->copy()->startOfMonth();
        $rangeEnd = $selectedMonth->copy()->endOfMonth();

        $users = $this->buildBaseUserQuery($filters)
            ->orderBy('users.name')
            ->get();

        $recordsByUser = $this->fetchMonthlyRecordsForUsers(
            $users->pluck('id'),
            $rangeStart,
            $rangeEnd
        );

        $rows = $users->map(
            fn (User $user) => $this->transformPayrollUser(
                request: $request,
                user: $user,
                monthlyRecords: $recordsByUser->get($user->id, collect())
            )
        )->values();

        $filename = $this->buildExportFilename($filters, $selectedMonth);

        return response()->streamDownload(function () use ($rows) {
            $handle = fopen('php://output', 'w');

            fwrite($handle, "\xEF\xBB\xBF");

            fputcsv($handle, [
                'Ma nhan vien',
                'Ho ten',
                'Phong ban',
                'Tong cong',
                'Cong tinh luong',
                'Luong phong ban',
                'Luong / cong',
                'Luong thuc nhan',
            ]);

            foreach ($rows as $row) {
                fputcsv($handle, [
                    $row['employee_code'] ?? '',
                    $row['name'] ?? '',
                    $row['department'] ?? '',
                    number_format((float) ($row['total_work_units'] ?? 0), 1, '.', ''),
                    number_format((float) ($row['paid_work_units'] ?? 0), 1, '.', ''),
                    $this->formatCurrencyForCsv((float) ($row['monthly_salary'] ?? 0)),
                    $this->formatCurrencyForCsv((float) ($row['unit_salary'] ?? 0)),
                    $this->formatCurrencyForCsv((float) ($row['salary_amount'] ?? 0)),
                ]);
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }

    private function buildBaseUserQuery(array $filters)
    {
        return User::query()
            ->leftJoin('roles', 'users.role_id', '=', 'roles.id')
            ->leftJoin('departments', 'users.department_id', '=', 'departments.id')
            ->where('users.is_active', true)
            ->where(function ($query) {
                $query
                    ->whereNull('roles.code')
                    ->orWhere('roles.code', '!=', 'admin');
            })
            ->select([
                'users.*',
                'roles.name as role_name',
                'roles.code as role_code',
                'departments.name as department_name',
                'departments.code as department_code',
                'departments.monthly_salary as department_monthly_salary',
            ])
            ->when(
                $filters['search'] ?? null,
                function ($query, $search) {
                    $query->where(function ($innerQuery) use ($search) {
                        $innerQuery
                            ->where('users.employee_code', 'like', '%' . $search . '%')
                            ->orWhere('users.name', 'like', '%' . $search . '%')
                            ->orWhere('users.email', 'like', '%' . $search . '%')
                            ->orWhere('users.phone', 'like', '%' . $search . '%');
                    });
                }
            )
            ->when(
                $filters['department_id'] ?? null,
                fn ($query, $departmentId) => $query->where('users.department_id', $departmentId)
            );
    }

    private function fetchMonthlyRecordsForUsers(
        Collection $userIds,
        Carbon $rangeStart,
        Carbon $rangeEnd
    ): Collection {
        if ($userIds->isEmpty()) {
            return collect();
        }

        return AttendanceRecord::query()
            ->whereIn('user_id', $userIds)
            ->whereBetween('check_date', [
                $rangeStart->toDateString(),
                $rangeEnd->toDateString(),
            ])
            ->where('status', 'valid')
            ->orderBy('check_date')
            ->orderBy('check_time')
            ->get()
            ->groupBy('user_id');
    }

    private function buildPayrollSummary(
        Collection $users,
        Collection $monthlyRecordsByUser,
        Carbon $selectedMonth
    ): array {
        $totalWorkUnits = 0.0;
        $totalPaidWorkUnits = 0.0;
        $totalMonthlySalary = 0.0;
        $totalSalaryAmount = 0.0;

        foreach ($users as $user) {
            $payroll = $this->calculatePayrollForUser(
                $user,
                $monthlyRecordsByUser->get($user->id, collect())
            );

            $totalWorkUnits += $payroll['total_work_units'];
            $totalPaidWorkUnits += $payroll['paid_work_units'];
            $totalMonthlySalary += $payroll['monthly_salary'];
            $totalSalaryAmount += $payroll['salary_amount'];
        }

        return [
            'month' => $selectedMonth->format('Y-m'),
            'month_label' => 'Thang ' . $selectedMonth->format('m/Y'),
            'standard_work_units' => self::STANDARD_WORK_UNITS,
            'total_users' => $users->count(),
            'total_work_units' => round($totalWorkUnits, 2),
            'total_paid_work_units' => round($totalPaidWorkUnits, 2),
            'total_monthly_salary' => round($totalMonthlySalary, 2),
            'total_salary_amount' => round($totalSalaryAmount, 2),
        ];
    }

    private function transformPayrollUser(
        Request $request,
        User $user,
        Collection $monthlyRecords
    ): array {
        $payroll = $this->calculatePayrollForUser($user, $monthlyRecords);

        return [
            'id' => $user->id,
            'employee_code' => $user->employee_code,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_path' => $user->avatar_path,
            'avatar_url' => $this->resolveAvatarUrl($request, $user->avatar_path),
            'department' => $user->department_name,
            'department_code' => $user->department_code,
            'monthly_salary' => $payroll['monthly_salary'],
            'total_work_units' => $payroll['total_work_units'],
            'paid_work_units' => $payroll['paid_work_units'],
            'unit_salary' => $payroll['unit_salary'],
            'salary_amount' => $payroll['salary_amount'],
        ];
    }

    private function calculatePayrollForUser(User $user, Collection $monthlyRecords): array
    {
        $totalWorkUnits = $this->calculateTotalWorkUnits($monthlyRecords);
        $paidWorkUnits = min($totalWorkUnits, self::STANDARD_WORK_UNITS);
        $monthlySalary = round((float) ($user->department_monthly_salary ?? 0), 2);
        $unitSalaryRaw = $monthlySalary > 0
            ? $monthlySalary / self::STANDARD_WORK_UNITS
            : 0.0;
        $salaryAmount = round($paidWorkUnits * $unitSalaryRaw, 2);

        return [
            'monthly_salary' => $monthlySalary,
            'total_work_units' => round($totalWorkUnits, 2),
            'paid_work_units' => round($paidWorkUnits, 2),
            'unit_salary' => round($unitSalaryRaw, 2),
            'salary_amount' => $salaryAmount,
        ];
    }

    private function calculateTotalWorkUnits(Collection $monthlyRecords): float
    {
        if ($monthlyRecords->isEmpty()) {
            return 0.0;
        }

        $groupedByDate = $monthlyRecords->groupBy(
            fn (AttendanceRecord $record) => $record->check_date->toDateString()
        );

        $totalWorkUnits = 0.0;

        foreach ($groupedByDate as $records) {
            $metrics = $this->calculateWorkUnitsForRecords($records);
            $totalWorkUnits += $metrics['work_units'];
        }

        return round($totalWorkUnits, 2);
    }

    private function calculateWorkUnitsForRecords(Collection $records): array
    {
        $checkTypes = $records
            ->pluck('check_type')
            ->filter()
            ->values();

        $morningComplete = $checkTypes->contains('morning_check_in')
            && $checkTypes->contains('morning_check_out');
        $afternoonComplete = $checkTypes->contains('afternoon_check_in')
            && $checkTypes->contains('afternoon_check_out');

        $workUnits = 0.0;

        if ($morningComplete) {
            $workUnits += 0.5;
        }

        if ($afternoonComplete) {
            $workUnits += 0.5;
        }

        return [
            'work_units' => $workUnits,
        ];
    }

    private function resolveAvatarUrl(Request $request, ?string $avatarPath): ?string
    {
        if (! $avatarPath) {
            return null;
        }

        return rtrim($request->root(), '/') . '/api/avatars/' . rawurlencode(basename($avatarPath));
    }

    private function formatCurrencyForCsv(float $value): string
    {
        if (fmod($value, 1.0) === 0.0) {
            return number_format($value, 0, '.', ',');
        }

        return number_format($value, 2, '.', ',');
    }

    private function buildExportFilename(array $filters, Carbon $selectedMonth): string
    {
        $departmentSuffix = 'tat_ca';

        if (isset($filters['department_id'])) {
            $department = Department::query()->find($filters['department_id']);

            if ($department) {
                $normalizedName = Str::of($department->name)
                    ->ascii()
                    ->replaceMatches('/[^A-Za-z0-9]+/', '_')
                    ->trim('_')
                    ->value();

                $departmentSuffix = $normalizedName !== '' ? $normalizedName : ('phong_ban_' . $department->id);
            }
        }

        return 'Bang_luong_' . $departmentSuffix . '_' . $selectedMonth->format('Y_m') . '.csv';
    }
}
