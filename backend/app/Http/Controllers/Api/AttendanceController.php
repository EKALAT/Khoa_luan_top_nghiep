<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AttendanceLog;
use App\Models\AttendanceRecord;
use App\Models\ShiftRule;
use App\Models\WorkLocation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AttendanceController extends Controller
{
    public function checkIn(Request $request): JsonResponse
    {
        return $this->handleAttendance($request, 'check_in');
    }

    public function checkOut(Request $request): JsonResponse
    {
        return $this->handleAttendance($request, 'check_out');
    }

    public function networkCheck(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'work_location_id' => ['required', 'integer', 'exists:work_locations,id'],
            'network_info' => ['nullable', 'string', 'max:255'],
        ]);

        $workLocation = WorkLocation::query()
            ->where('is_active', true)
            ->find($validated['work_location_id']);

        if (! $workLocation) {
            return response()->json([
                'message' => 'Địa điểm làm việc không hợp lệ hoặc đã bị vô hiệu hóa.',
            ], 422);
        }

        $requestIp = $this->resolveRequestIp($request);
        $isAllowed = $this->passesNetworkRule(
            $workLocation->allowed_network,
            $requestIp,
        );

        return response()->json([
            'message' => $isAllowed
                ? 'Mạng hiện tại hợp lệ để chấm công.'
                : 'Mạng hiện tại không hợp lệ để chấm công.',
            'reason' => $isAllowed ? null : 'wrong_network',
            'data' => [
                'work_location_id' => $workLocation->id,
                'work_location_name' => $workLocation->name,
                'request_ip' => $requestIp,
                'allowed_network' => $workLocation->allowed_network,
                'client_network_info' => $validated['network_info'] ?? null,
                'is_allowed' => $isAllowed,
            ],
        ], $isAllowed ? 200 : 422);
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $filters = $request->validate([
            'date' => ['nullable', 'date_format:Y-m-d'],
            'from' => ['nullable', 'date_format:Y-m-d'],
            'to' => ['nullable', 'date_format:Y-m-d', 'after_or_equal:from'],
            'check_type' => ['nullable', Rule::in([
                'morning_check_in',
                'morning_check_out',
                'afternoon_check_in',
                'afternoon_check_out',
            ])],
            'status' => ['nullable', Rule::in(['valid', 'invalid'])],
        ]);

        $records = AttendanceRecord::query()
            ->with(['workLocation'])
            ->where('user_id', $user->id)
            ->when(
                $filters['date'] ?? null,
                fn ($query, $date) => $query->whereDate('check_date', $date)
            )
            ->when(
                $filters['from'] ?? null,
                fn ($query, $from) => $query->whereDate('check_date', '>=', $from)
            )
            ->when(
                $filters['to'] ?? null,
                fn ($query, $to) => $query->whereDate('check_date', '<=', $to)
            )
            ->when(
                $filters['check_type'] ?? null,
                fn ($query, $checkType) => $query->where('check_type', $checkType)
            )
            ->when(
                $filters['status'] ?? null,
                fn ($query, $status) => $query->where('status', $status)
            )
            ->orderByDesc('check_date')
            ->orderByDesc('check_time')
            ->paginate(10)
            ->appends($request->query());

        return response()->json($records);
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $record = AttendanceRecord::query()
            ->with(['workLocation', 'logs'])
            ->where('user_id', $user->id)
            ->findOrFail($id);

        return response()->json([
            'data' => $record,
        ]);
    }

    public function logs(Request $request): JsonResponse
    {
        $user = $request->user();

        $logs = AttendanceLog::query()
            ->with(['attendanceRecord'])
            ->where('user_id', $user->id)
            ->orderByDesc('captured_at')
            ->paginate(20);

        return response()->json($logs);
    }

    public function logShow(Request $request, int $id): JsonResponse
    {
        $user = $request->user();

        $log = AttendanceLog::query()
            ->with(['attendanceRecord'])
            ->where('user_id', $user->id)
            ->findOrFail($id);

        return response()->json([
            'data' => $log,
        ]);
    }

    private function handleAttendance(Request $request, string $mode): JsonResponse
    {
        $validated = $request->validate([
            'work_location_id' => ['required', 'integer', 'exists:work_locations,id'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'accuracy_m' => ['required', 'numeric', 'min:0'],
            'network_info' => ['nullable', 'string', 'max:255'],
            'device_info' => ['nullable', 'string'],
        ]);

        $user = $request->user();

        if (! $user) {
            return response()->json([
                'message' => 'Unauthenticated.',
            ], 401);
        }

        $requestIp = $this->resolveRequestIp($request);
        $networkLogInfo = $this->buildNetworkLogInfo(
            $validated['network_info'] ?? null,
            $requestIp,
        );

        $shiftRule = ShiftRule::query()
            ->where('is_active', true)
            ->orderBy('id')
            ->first();

        if (! $shiftRule) {
            return response()->json([
                'message' => 'Chưa có cấu hình ca làm việc đang hoạt động.',
            ], 422);
        }

        $workLocation = WorkLocation::query()
            ->where('is_active', true)
            ->find($validated['work_location_id']);

        if (! $workLocation) {
            return response()->json([
                'message' => 'Địa điểm làm việc không hợp lệ hoặc đã bị vô hiệu hóa.',
            ], 422);
        }

        $now = now();
        $timeNow = $now->format('H:i:s');
        $checkDate = $now->toDateString();
        $checkTime = $now->format('H:i:s');

        $checkType = $this->resolveCheckType($mode, $shiftRule, $timeNow);

        if (! $checkType) {
            $this->createInvalidLog(
                userId: $user->id,
                attendanceRecordId: null,
                lat: (float) $validated['latitude'],
                lng: (float) $validated['longitude'],
                accuracyM: (float) $validated['accuracy_m'],
                deviceInfo: $validated['device_info'] ?? null,
                networkInfo: $networkLogInfo,
                reason: 'wrong_time_window',
            );

            return response()->json([
                'message' => 'Thời điểm chấm công không nằm trong khung giờ hợp lệ.',
                'reason' => 'wrong_time_window',
            ], 422);
        }

        $existingRecord = AttendanceRecord::query()
            ->where('user_id', $user->id)
            ->where('check_date', $checkDate)
            ->where('check_type', $checkType)
            ->first();

        if ($existingRecord) {
            $this->createInvalidLog(
                userId: $user->id,
                attendanceRecordId: $existingRecord->id,
                lat: (float) $validated['latitude'],
                lng: (float) $validated['longitude'],
                accuracyM: (float) $validated['accuracy_m'],
                deviceInfo: $validated['device_info'] ?? null,
                networkInfo: $networkLogInfo,
                reason: 'duplicate_check',
            );

            return response()->json([
                'message' => 'Bạn đã chấm công cho mốc này trong ngày.',
                'reason' => 'duplicate_check',
            ], 422);
        }

        $missingCheckInMessage = $this->getMissingCheckInMessage(
            $user->id,
            $checkDate,
            $checkType,
        );

        if ($missingCheckInMessage) {
            $this->createInvalidLog(
                userId: $user->id,
                attendanceRecordId: null,
                lat: (float) $validated['latitude'],
                lng: (float) $validated['longitude'],
                accuracyM: (float) $validated['accuracy_m'],
                deviceInfo: $validated['device_info'] ?? null,
                networkInfo: $networkLogInfo,
                reason: 'missing_check_in',
            );

            return response()->json([
                'message' => $missingCheckInMessage,
                'reason' => 'missing_check_in',
            ], 422);
        }

        $distanceM = $this->calculateDistanceMeters(
            (float) $validated['latitude'],
            (float) $validated['longitude'],
            (float) $workLocation->latitude,
            (float) $workLocation->longitude,
        );

        if ((float) $validated['accuracy_m'] > 20) {
            $this->createInvalidLog(
                userId: $user->id,
                attendanceRecordId: null,
                lat: (float) $validated['latitude'],
                lng: (float) $validated['longitude'],
                accuracyM: (float) $validated['accuracy_m'],
                deviceInfo: $validated['device_info'] ?? null,
                networkInfo: $networkLogInfo,
                reason: 'low_accuracy',
            );

            return response()->json([
                'message' => 'Độ chính xác GPS vượt quá ngưỡng cho phép.',
                'reason' => 'low_accuracy',
            ], 422);
        }

        if ($distanceM > (float) $workLocation->radius_m) {
            $this->createInvalidLog(
                userId: $user->id,
                attendanceRecordId: null,
                lat: (float) $validated['latitude'],
                lng: (float) $validated['longitude'],
                accuracyM: (float) $validated['accuracy_m'],
                deviceInfo: $validated['device_info'] ?? null,
                networkInfo: $networkLogInfo,
                reason: 'outside_geofence',
            );

            return response()->json([
                'message' => 'Bạn đang ở ngoài phạm vi cho phép.',
                'reason' => 'outside_geofence',
                'distance_m' => round($distanceM, 2),
            ], 422);
        }

        if (! $this->passesNetworkRule(
            $workLocation->allowed_network,
            $requestIp,
        )) {
            $this->createInvalidLog(
                userId: $user->id,
                attendanceRecordId: null,
                lat: (float) $validated['latitude'],
                lng: (float) $validated['longitude'],
                accuracyM: (float) $validated['accuracy_m'],
                deviceInfo: $validated['device_info'] ?? null,
                networkInfo: $networkLogInfo,
                reason: 'wrong_network',
            );

            return response()->json([
                'message' => 'Thiết bị không kết nối đúng mạng hợp lệ.',
                'reason' => 'wrong_network',
                'data' => [
                    'work_location_id' => $workLocation->id,
                    'work_location_name' => $workLocation->name,
                    'request_ip' => $requestIp,
                    'allowed_network' => $workLocation->allowed_network,
                    'client_network_info' => $validated['network_info'] ?? null,
                ],
            ], 422);
        }

        $record = DB::transaction(function () use (
            $user,
            $workLocation,
            $checkType,
            $checkDate,
            $checkTime,
            $distanceM,
            $validated,
            $networkLogInfo
        ) {
            $attendanceRecord = AttendanceRecord::create([
                'user_id' => $user->id,
                'work_location_id' => $workLocation->id,
                'check_type' => $checkType,
                'status' => 'valid',
                'check_date' => $checkDate,
                'check_time' => $checkTime,
                'distance_m' => round($distanceM, 2),
                'accuracy_m' => $validated['accuracy_m'],
                'reason' => null,
            ]);

            AttendanceLog::create([
                'user_id' => $user->id,
                'attendance_record_id' => $attendanceRecord->id,
                'lat' => $validated['latitude'],
                'lng' => $validated['longitude'],
                'accuracy_m' => $validated['accuracy_m'],
                'captured_at' => now(),
                'device_info' => $validated['device_info'] ?? null,
                'network_info' => $networkLogInfo,
                'result' => 'valid',
                'reason' => null,
            ]);

            return $attendanceRecord;
        });

        return response()->json([
            'message' => 'Chấm công thành công.',
            'data' => $record,
        ], 201);
    }

    private function resolveCheckType(string $mode, ShiftRule $shiftRule, string $timeNow): ?string
    {
        if ($mode === 'check_in') {
            if ($this->isBetweenInclusive($timeNow, $shiftRule->morning_check_in_start, $shiftRule->morning_check_in_end)) {
                return 'morning_check_in';
            }

            if ($this->isBetweenInclusive($timeNow, $shiftRule->afternoon_check_in_start, $shiftRule->afternoon_check_in_end)) {
                return 'afternoon_check_in';
            }

            return null;
        }

        if ($this->isBetweenInclusive($timeNow, $shiftRule->morning_check_out_start, $shiftRule->morning_check_out_end)) {
            return 'morning_check_out';
        }

        if ($this->isBetweenInclusive($timeNow, $shiftRule->afternoon_check_out_start, $shiftRule->afternoon_check_out_end)) {
            return 'afternoon_check_out';
        }

        return null;
    }

    private function isBetweenInclusive(string $value, string $start, string $end): bool
    {
        return $value >= $start && $value <= $end;
    }

    private function passesNetworkRule(?string $allowedNetwork, string $requestIp): bool
    {
        if (! $allowedNetwork || trim($allowedNetwork) === '') {
            return true;
        }

        $rules = array_filter(array_map('trim', explode(',', $allowedNetwork)));

        foreach ($rules as $rule) {
            if (filter_var($rule, FILTER_VALIDATE_IP) && $requestIp === $rule) {
                return true;
            }

            if ($this->isIpCidr($rule) && $this->ipMatchesCidr($requestIp, $rule)) {
                return true;
            }
        }

        return false;
    }

    private function getMissingCheckInMessage(int $userId, string $checkDate, string $checkType): ?string
    {
        $requiredCheckInType = match ($checkType) {
            'morning_check_out' => 'morning_check_in',
            'afternoon_check_out' => 'afternoon_check_in',
            default => null,
        };

        if (! $requiredCheckInType) {
            return null;
        }

        $hasValidCheckIn = AttendanceRecord::query()
            ->where('user_id', $userId)
            ->where('check_date', $checkDate)
            ->where('check_type', $requiredCheckInType)
            ->where('status', 'valid')
            ->exists();

        if ($hasValidCheckIn) {
            return null;
        }

        return $checkType === 'morning_check_out'
            ? 'Bạn chưa chấm công vào ca sáng nên không thể chấm công ra ca sáng.'
            : 'Bạn chưa chấm công vào ca chiều nên không thể chấm công ra ca chiều.';
    }

    private function calculateDistanceMeters(
        float $lat1,
        float $lng1,
        float $lat2,
        float $lng2
    ): float {
        $earthRadius = 6371000;

        $dLat = deg2rad($lat2 - $lat1);
        $dLng = deg2rad($lng2 - $lng1);

        $a = sin($dLat / 2) * sin($dLat / 2)
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLng / 2) * sin($dLng / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earthRadius * $c;
    }

    private function resolveRequestIp(Request $request): string
    {
        $forwardedFor = $request->header('X-Forwarded-For');

        if ($forwardedFor) {
            $candidates = array_map('trim', explode(',', $forwardedFor));

            foreach ($candidates as $candidate) {
                if (filter_var($candidate, FILTER_VALIDATE_IP)) {
                    return $candidate;
                }
            }
        }

        $realIp = $request->header('X-Real-IP');

        if ($realIp && filter_var($realIp, FILTER_VALIDATE_IP)) {
            return $realIp;
        }

        return $request->ip() ?? 'unknown';
    }

    private function buildNetworkLogInfo(?string $networkInfo, string $requestIp): string
    {
        $parts = [
            'request_ip=' . $requestIp,
        ];

        if ($networkInfo && trim($networkInfo) !== '') {
            $parts[] = 'client_network=' . trim($networkInfo);
        }

        return implode('; ', $parts);
    }

    private function isIpCidr(string $value): bool
    {
        if (! str_contains($value, '/')) {
            return false;
        }

        [$subnet, $prefixLength] = explode('/', $value, 2);

        if (! filter_var($subnet, FILTER_VALIDATE_IP) || ! ctype_digit($prefixLength)) {
            return false;
        }

        $maxPrefixLength = filter_var($subnet, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6) ? 128 : 32;

        return (int) $prefixLength >= 0 && (int) $prefixLength <= $maxPrefixLength;
    }

    private function ipMatchesCidr(string $ip, string $cidr): bool
    {
        if (! filter_var($ip, FILTER_VALIDATE_IP)) {
            return false;
        }

        [$subnet, $prefixLength] = explode('/', $cidr, 2);

        $prefixLength = (int) $prefixLength;

        $isIpv6Ip = filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6);
        $isIpv6Subnet = filter_var($subnet, FILTER_VALIDATE_IP, FILTER_FLAG_IPV6);

        if ($isIpv6Ip !== $isIpv6Subnet) {
            return false;
        }

        $ipBinary = inet_pton($ip);
        $subnetBinary = inet_pton($subnet);

        if ($ipBinary === false || $subnetBinary === false) {
            return false;
        }

        $fullBytes = intdiv($prefixLength, 8);
        $remainingBits = $prefixLength % 8;

        if ($fullBytes > 0 && substr($ipBinary, 0, $fullBytes) !== substr($subnetBinary, 0, $fullBytes)) {
            return false;
        }

        if ($remainingBits === 0) {
            return true;
        }

        $mask = (0xFF << (8 - $remainingBits)) & 0xFF;

        return (ord($ipBinary[$fullBytes]) & $mask) === (ord($subnetBinary[$fullBytes]) & $mask);
    }

    private function createInvalidLog(
        int $userId,
        ?int $attendanceRecordId,
        float $lat,
        float $lng,
        float $accuracyM,
        ?string $deviceInfo,
        ?string $networkInfo,
        string $reason
    ): void {
        AttendanceLog::create([
            'user_id' => $userId,
            'attendance_record_id' => $attendanceRecordId,
            'lat' => $lat,
            'lng' => $lng,
            'accuracy_m' => $accuracyM,
            'captured_at' => now(),
            'device_info' => $deviceInfo,
            'network_info' => $networkInfo,
            'result' => 'invalid',
            'reason' => $reason,
        ]);
    }
}
