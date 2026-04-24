<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AttendanceRecord;
use App\Models\User;
use Illuminate\Database\Query\JoinClause;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Symfony\Component\HttpFoundation\StreamedResponse;

class AdminAttendanceController extends Controller
{
    private const EXPECTED_VALID_RECORDS = 4;

    public function overview(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'date' => ['nullable', 'date_format:Y-m-d'],
            'department_id' => ['nullable', 'integer', 'exists:departments,id'],
            'search' => ['nullable', 'string', 'max:100'],
            'status' => ['nullable', Rule::in([
                'not_checked_in',
                'partial',
                'completed',
            ])],
        ]);

        $date = $filters['date'] ?? now()->toDateString();

        $attendanceSummary = AttendanceRecord::query()
            ->select([
                'user_id',
                DB::raw('COUNT(*) as valid_record_count'),
                DB::raw('MAX(check_time) as latest_check_time'),
            ])
            ->whereDate('check_date', $date)
            ->where('status', 'valid')
            ->groupBy('user_id');

        $baseQuery = User::query()
            ->leftJoinSub($attendanceSummary, 'attendance_summary', function (JoinClause $join) {
                $join->on('users.id', '=', 'attendance_summary.user_id');
            })
            ->leftJoin('roles', 'users.role_id', '=', 'roles.id')
            ->leftJoin('departments', 'users.department_id', '=', 'departments.id')
            ->where('users.is_active', true)
            ->select([
                'users.*',
                'roles.name as role_name',
                'roles.code as role_code',
                'departments.name as department_name',
                'departments.code as department_code',
                DB::raw('COALESCE(attendance_summary.valid_record_count, 0) as valid_record_count'),
                'attendance_summary.latest_check_time',
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

        $summaryQuery = clone $baseQuery;

        $totalUsers = (clone $summaryQuery)->count('users.id');
        $checkedInCount = $this->applyAttendanceStatusFilter(
            clone $summaryQuery,
            'checked_in'
        )->count('users.id');
        $notCheckedInCount = $this->applyAttendanceStatusFilter(
            clone $summaryQuery,
            'not_checked_in'
        )->count('users.id');
        $partialCount = $this->applyAttendanceStatusFilter(
            clone $summaryQuery,
            'partial'
        )->count('users.id');
        $completedCount = $this->applyAttendanceStatusFilter(
            clone $summaryQuery,
            'completed'
        )->count('users.id');

        $matchingUserIds = (clone $summaryQuery)->pluck('users.id');

        $recentActivities = $matchingUserIds->isEmpty()
            ? []
            : AttendanceRecord::query()
                ->with([
                    'user.department',
                    'workLocation',
                ])
                ->whereIn('user_id', $matchingUserIds)
                ->whereDate('check_date', $date)
                ->where('status', 'valid')
                ->orderByDesc('check_time')
                ->limit(3)
                ->get()
                ->map(function (AttendanceRecord $record) use ($request) {
                    $user = $record->user;

                    return [
                        'id' => $record->id,
                        'employee_code' => $user?->employee_code,
                        'name' => $user?->name,
                        'department' => $user?->department?->name,
                        'avatar_path' => $user?->avatar_path,
                        'avatar_url' => $this->resolveAvatarUrl($request, $user?->avatar_path),
                        'check_type' => $record->check_type,
                        'check_time' => $record->check_time,
                        'work_location_name' => $record->workLocation?->name,
                    ];
                })
                ->values()
                ->all();

        $listQuery = clone $baseQuery;
        $this->applyAttendanceStatusFilter($listQuery, $filters['status'] ?? null);

        $paginator = $listQuery
            ->orderBy('users.name')
            ->paginate(12)
            ->appends($request->query());

        $recordsByUser = AttendanceRecord::query()
            ->with('workLocation')
            ->whereIn('user_id', $paginator->getCollection()->pluck('id'))
            ->whereDate('check_date', $date)
            ->where('status', 'valid')
            ->orderBy('check_time')
            ->get()
            ->groupBy('user_id');

        $paginator->setCollection(
            $paginator->getCollection()->map(
                fn (User $user) => $this->transformUser(
                    request: $request,
                    user: $user,
                    attendanceRecords: $recordsByUser->get($user->id, collect())
                )
            )
        );

        return response()->json([
            ...$paginator->toArray(),
            'summary' => [
                'date' => $date,
                'expected_valid_records' => self::EXPECTED_VALID_RECORDS,
                'total_users' => $totalUsers,
                'checked_in_count' => $checkedInCount,
                'not_checked_in_count' => $notCheckedInCount,
                'partial_count' => $partialCount,
                'completed_count' => $completedCount,
                'recent_activities' => $recentActivities,
            ],
        ]);
    }

    public function monthlyOverview(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'month' => ['nullable', 'date_format:Y-m'],
            'department_id' => ['nullable', 'integer', 'exists:departments,id'],
            'search' => ['nullable', 'string', 'max:100'],
        ]);

        $selectedMonth = isset($filters['month'])
            ? Carbon::createFromFormat('Y-m', $filters['month'])->startOfMonth()
            : now()->startOfMonth();

        [$rangeStart, $rangeEnd, $trackedDateStrings] = $this->resolveTrackedMonthRange($selectedMonth);
        $trackedDayCount = count($trackedDateStrings);

        $baseQuery = User::query()
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

        $summaryQuery = clone $baseQuery;
        $paginator = (clone $baseQuery)
            ->orderBy('users.name')
            ->paginate(8)
            ->appends($request->query());

        $allUserIds = (clone $summaryQuery)->pluck('users.id');
        $pageUserIds = $paginator->getCollection()->pluck('id');

        $allUserRecords = $this->fetchMonthlyRecordsForUsers(
            $allUserIds,
            $rangeStart,
            $rangeEnd
        );

        $pageUserRecords = $this->fetchMonthlyRecordsForUsers(
            $pageUserIds,
            $rangeStart,
            $rangeEnd
        );

        $summary = $this->buildMonthlySummary(
            users: $summaryQuery->get(),
            monthlyRecordsByUser: $allUserRecords,
            trackedDayCount: $trackedDayCount,
            selectedMonth: $selectedMonth,
            rangeEnd: $rangeEnd,
        );

        $paginator->setCollection(
            $paginator->getCollection()->map(
                fn (User $user) => $this->transformMonthlyUser(
                    request: $request,
                    user: $user,
                    monthlyRecords: $pageUserRecords->get($user->id, collect()),
                    trackedDateStrings: $trackedDateStrings
                )
            )
        );

        return response()->json([
            ...$paginator->toArray(),
            'summary' => $summary,
        ]);
    }

    public function exportMonthlyCsv(Request $request): StreamedResponse
    {
        $filters = $request->validate([
            'month' => ['nullable', 'date_format:Y-m'],
            'department_id' => ['nullable', 'integer', 'exists:departments,id'],
            'search' => ['nullable', 'string', 'max:100'],
        ]);

        $selectedMonth = isset($filters['month'])
            ? Carbon::createFromFormat('Y-m', $filters['month'])->startOfMonth()
            : now()->startOfMonth();

        [$rangeStart, $rangeEnd, $trackedDateStrings] = $this->resolveTrackedMonthRange($selectedMonth);

        $users = User::query()
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
            )
            ->orderBy('users.name')
            ->get();

        $recordsByUser = $this->fetchMonthlyRecordsForUsers(
            $users->pluck('id'),
            $rangeStart,
            $rangeEnd
        );

        $rows = $users->map(
            fn (User $user) => $this->transformMonthlyUser(
                request: $request,
                user: $user,
                monthlyRecords: $recordsByUser->get($user->id, collect()),
                trackedDateStrings: $trackedDateStrings
            )
        )->values();

        $filename = 'bang_cong_' . $selectedMonth->format('Y_m') . '.csv';

        return response()->streamDownload(function () use ($rows, $trackedDateStrings) {
            $handle = fopen('php://output', 'w');

            fwrite($handle, "\xEF\xBB\xBF");

            $header = ['Ma nhan vien', 'Ho ten', 'Phong ban'];
            foreach ($trackedDateStrings as $date) {
                $header[] = Carbon::parse($date)->format('d');
            }
            $header[] = 'Tong cong';

            fputcsv($handle, $header);

            foreach ($rows as $row) {
                $dailyBreakdown = collect($row['daily_breakdown'] ?? [])->keyBy('date');
                $line = [
                    $row['employee_code'] ?? '',
                    $row['name'] ?? '',
                    $row['department'] ?? '',
                ];

                foreach ($trackedDateStrings as $date) {
                    $day = $dailyBreakdown->get($date);

                    if (! is_array($day) || ($day['status'] ?? 'not_recorded') === 'not_recorded') {
                        $line[] = '';
                        continue;
                    }

                    $line[] = number_format((float) ($day['work_units'] ?? 0), 1, '.', '');
                }

                $line[] = number_format((float) ($row['total_work_units'] ?? 0), 1, '.', '');
                fputcsv($handle, $line);
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }

    private function applyAttendanceStatusFilter($query, ?string $status)
    {
        return match ($status) {
            'not_checked_in' => $query->whereRaw('COALESCE(attendance_summary.valid_record_count, 0) = 0'),
            'partial' => $query->whereRaw(
                'COALESCE(attendance_summary.valid_record_count, 0) BETWEEN 1 AND ?',
                [self::EXPECTED_VALID_RECORDS - 1]
            ),
            'completed' => $query->whereRaw(
                'COALESCE(attendance_summary.valid_record_count, 0) >= ?',
                [self::EXPECTED_VALID_RECORDS]
            ),
            'checked_in' => $query->whereRaw('COALESCE(attendance_summary.valid_record_count, 0) > 0'),
            default => $query,
        };
    }

    private function transformUser(
        Request $request,
        User $user,
        Collection $attendanceRecords
    ): array {
        /** @var Collection<int, AttendanceRecord> $attendanceRecords */
        $latestRecord = $attendanceRecords->sortByDesc('check_time')->first();
        $validRecordCount = (int) ($user->valid_record_count ?? 0);

        return [
            'id' => $user->id,
            'employee_code' => $user->employee_code,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_path' => $user->avatar_path,
            'avatar_url' => $this->resolveAvatarUrl($request, $user->avatar_path),
            'role' => $user->role_name,
            'role_code' => $user->role_code,
            'department' => $user->department_name,
            'department_code' => $user->department_code,
            'last_login_at' => $user->last_login_at,
            'attendance_status' => $this->resolveAttendanceStatus($validRecordCount),
            'valid_record_count' => $validRecordCount,
            'latest_check_time' => $latestRecord?->check_time,
            'latest_check_type' => $latestRecord?->check_type,
            'today_records' => $attendanceRecords
                ->map(fn (AttendanceRecord $record) => [
                    'id' => $record->id,
                    'check_type' => $record->check_type,
                    'check_time' => $record->check_time,
                    'work_location_name' => $record->workLocation?->name,
                ])
                ->values()
                ->all(),
        ];
    }

    private function resolveAttendanceStatus(int $validRecordCount): string
    {
        return match (true) {
            $validRecordCount <= 0 => 'not_checked_in',
            $validRecordCount >= self::EXPECTED_VALID_RECORDS => 'completed',
            default => 'partial',
        };
    }

    private function fetchMonthlyRecordsForUsers(
        Collection $userIds,
        ?Carbon $rangeStart,
        ?Carbon $rangeEnd
    ): Collection {
        if ($userIds->isEmpty() || ! $rangeStart || ! $rangeEnd) {
            return collect();
        }

        return AttendanceRecord::query()
            ->with('workLocation')
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

    private function buildMonthlySummary(
        Collection $users,
        Collection $monthlyRecordsByUser,
        int $trackedDayCount,
        Carbon $selectedMonth,
        ?Carbon $rangeEnd
    ): array {
        $employeeWithWorkCount = 0;
        $employeeWithoutWorkCount = 0;
        $totalWorkUnits = 0.0;
        $fullDayTotal = 0;
        $halfDayTotal = 0;
        $incompleteDayTotal = 0;
        $daysWithoutRecordTotal = 0;

        foreach ($users as $user) {
            $metrics = $this->calculateMonthlyMetrics(
                $monthlyRecordsByUser->get($user->id, collect()),
                $trackedDayCount
            );

            $totalWorkUnits += $metrics['total_work_units'];
            $fullDayTotal += $metrics['full_day_count'];
            $halfDayTotal += $metrics['half_day_count'];
            $incompleteDayTotal += $metrics['incomplete_day_count'];
            $daysWithoutRecordTotal += $metrics['days_without_record_count'];

            if ($metrics['total_work_units'] > 0) {
                $employeeWithWorkCount++;
            } else {
                $employeeWithoutWorkCount++;
            }
        }

        return [
            'month' => $selectedMonth->format('Y-m'),
            'month_label' => 'Thang ' . $selectedMonth->format('m/Y'),
            'tracked_day_count' => $trackedDayCount,
            'range_end' => $rangeEnd?->toDateString(),
            'total_users' => $users->count(),
            'employee_with_work_count' => $employeeWithWorkCount,
            'employee_without_work_count' => $employeeWithoutWorkCount,
            'total_work_units' => round($totalWorkUnits, 2),
            'full_day_total' => $fullDayTotal,
            'half_day_total' => $halfDayTotal,
            'incomplete_day_total' => $incompleteDayTotal,
            'days_without_record_total' => $daysWithoutRecordTotal,
        ];
    }

    private function transformMonthlyUser(
        Request $request,
        User $user,
        Collection $monthlyRecords,
        array $trackedDateStrings
    ): array {
        $recordsByDate = $monthlyRecords->groupBy(
            fn (AttendanceRecord $record) => $record->check_date->toDateString()
        );

        $dailyBreakdown = collect($trackedDateStrings)
            ->map(function (string $date) use ($recordsByDate) {
                $records = $recordsByDate->get($date, collect());
                $metrics = $this->calculateWorkUnitsForRecords($records);

                return [
                    'date' => $date,
                    'valid_record_count' => $records->count(),
                    'work_units' => $metrics['work_units'],
                    'status' => $this->resolveMonthlyDayStatus(
                        $records->count(),
                        $metrics['work_units']
                    ),
                    'moments' => $records
                        ->map(fn (AttendanceRecord $record) => [
                            'id' => $record->id,
                            'check_type' => $record->check_type,
                            'check_time' => $record->check_time,
                            'work_location_name' => $record->workLocation?->name,
                        ])
                        ->values()
                        ->all(),
                ];
            })
            ->values();

        $fullDayCount = $dailyBreakdown->where('status', 'full_day')->count();
        $halfDayCount = $dailyBreakdown->where('status', 'half_day')->count();
        $incompleteDayCount = $dailyBreakdown->where('status', 'incomplete')->count();
        $recordedDayCount = $dailyBreakdown->where('valid_record_count', '>', 0)->count();
        $daysWithoutRecordCount = $dailyBreakdown->count() - $recordedDayCount;
        $totalWorkUnits = $dailyBreakdown->sum('work_units');
        $latestDay = $dailyBreakdown
            ->where('valid_record_count', '>', 0)
            ->sortByDesc('date')
            ->first();

        return [
            'id' => $user->id,
            'employee_code' => $user->employee_code,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_path' => $user->avatar_path,
            'avatar_url' => $this->resolveAvatarUrl($request, $user->avatar_path),
            'role' => $user->role_name,
            'role_code' => $user->role_code,
            'department' => $user->department_name,
            'department_code' => $user->department_code,
            'last_login_at' => $user->last_login_at,
            'tracked_day_count' => $dailyBreakdown->count(),
            'recorded_day_count' => $recordedDayCount,
            'full_day_count' => $fullDayCount,
            'half_day_count' => $halfDayCount,
            'incomplete_day_count' => $incompleteDayCount,
            'days_without_record_count' => $daysWithoutRecordCount,
            'total_work_units' => round($totalWorkUnits, 2),
            'latest_attendance_date' => $latestDay['date'] ?? null,
            'latest_day_status' => $latestDay['status'] ?? null,
            'daily_breakdown' => $dailyBreakdown->all(),
        ];
    }

    private function calculateMonthlyMetrics(
        Collection $monthlyRecords,
        int $trackedDayCount
    ): array {
        if ($monthlyRecords->isEmpty()) {
            return [
                'recorded_day_count' => 0,
                'full_day_count' => 0,
                'half_day_count' => 0,
                'incomplete_day_count' => 0,
                'days_without_record_count' => $trackedDayCount,
                'total_work_units' => 0.0,
            ];
        }

        $groupedByDate = $monthlyRecords->groupBy(
            fn (AttendanceRecord $record) => $record->check_date->toDateString()
        );

        $fullDayCount = 0;
        $halfDayCount = 0;
        $incompleteDayCount = 0;
        $totalWorkUnits = 0.0;

        foreach ($groupedByDate as $records) {
            $metrics = $this->calculateWorkUnitsForRecords($records);
            $totalWorkUnits += $metrics['work_units'];

            if ($metrics['work_units'] >= 1) {
                $fullDayCount++;
                continue;
            }

            if ($metrics['work_units'] >= 0.5) {
                $halfDayCount++;
                continue;
            }

            $incompleteDayCount++;
        }

        $recordedDayCount = $groupedByDate->count();

        return [
            'recorded_day_count' => $recordedDayCount,
            'full_day_count' => $fullDayCount,
            'half_day_count' => $halfDayCount,
            'incomplete_day_count' => $incompleteDayCount,
            'days_without_record_count' => max($trackedDayCount - $recordedDayCount, 0),
            'total_work_units' => round($totalWorkUnits, 2),
        ];
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
            'morning_complete' => $morningComplete,
            'afternoon_complete' => $afternoonComplete,
            'work_units' => $workUnits,
        ];
    }

    private function resolveMonthlyDayStatus(int $validRecordCount, float $workUnits): string
    {
        if ($validRecordCount <= 0) {
            return 'not_recorded';
        }

        if ($workUnits >= 1) {
            return 'full_day';
        }

        if ($workUnits >= 0.5) {
            return 'half_day';
        }

        return 'incomplete';
    }

    private function resolveTrackedMonthRange(Carbon $selectedMonth): array
    {
        $monthStart = $selectedMonth->copy()->startOfMonth();
        $monthEnd = $selectedMonth->copy()->endOfMonth();
        $dates = [];
        $cursor = $monthStart->copy();

        while ($cursor->lessThanOrEqualTo($monthEnd)) {
            $dates[] = $cursor->toDateString();
            $cursor->addDay();
        }

        return [$monthStart, $monthEnd, $dates];
    }

    private function resolveAvatarUrl(Request $request, ?string $avatarPath): ?string
    {
        if (! $avatarPath) {
            return null;
        }

        return rtrim($request->root(), '/') . '/api/avatars/' . rawurlencode(basename($avatarPath));
    }
}
