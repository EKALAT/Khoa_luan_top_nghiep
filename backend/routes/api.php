<?php

use App\Http\Controllers\Api\AdminAttendanceController;
use App\Http\Controllers\Api\AdminDepartmentController;
use App\Http\Controllers\Api\AdminLookupController;
use App\Http\Controllers\Api\AdminPayrollController;
use App\Http\Controllers\Api\AdminUserController;
use App\Http\Controllers\Api\AttendanceController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\ShiftRuleController;
use App\Http\Controllers\Api\WorkLocationController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function () {
    Route::post('/login', [AuthController::class, 'login']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::get('/avatars/{filename}', [ProfileController::class, 'avatar'])
    ->where('filename', '.*');

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/work-locations', [WorkLocationController::class, 'index']);
    Route::get('/work-locations/{workLocation}', [WorkLocationController::class, 'show']);
    Route::get('/shift-rules', [ShiftRuleController::class, 'index']);
    Route::get('/shift-rules/{shiftRule}', [ShiftRuleController::class, 'show']);

    Route::get('/profile', [ProfileController::class, 'show']);
    Route::put('/profile', [ProfileController::class, 'update']);
    Route::post('/profile/avatar', [ProfileController::class, 'uploadAvatar']);

    Route::post('/attendance/check-in', [AttendanceController::class, 'checkIn']);
    Route::post('/attendance/check-out', [AttendanceController::class, 'checkOut']);
    Route::get('/attendance/network-check', [AttendanceController::class, 'networkCheck']);

    Route::get('/attendance/logs', [AttendanceController::class, 'logs']);
    Route::get('/attendance/logs/{id}', [AttendanceController::class, 'logShow']);
    Route::get('/attendance', [AttendanceController::class, 'index']);
    Route::get('/attendance/{id}', [AttendanceController::class, 'show']);
});

Route::middleware(['auth:sanctum', 'admin'])->group(function () {
    Route::post('/work-locations', [WorkLocationController::class, 'store']);
    Route::put('/work-locations/{workLocation}', [WorkLocationController::class, 'update']);
    Route::delete('/work-locations/{workLocation}', [WorkLocationController::class, 'destroy']);

    Route::post('/shift-rules', [ShiftRuleController::class, 'store']);
    Route::put('/shift-rules/{shiftRule}', [ShiftRuleController::class, 'update']);
    Route::delete('/shift-rules/{shiftRule}', [ShiftRuleController::class, 'destroy']);

    Route::prefix('admin')->group(function () {
        Route::get('/roles', [AdminLookupController::class, 'roles']);
        Route::get('/departments', [AdminLookupController::class, 'departments']);
        Route::get('/work-locations', [WorkLocationController::class, 'adminIndex']);
        Route::get('/shift-rules', [ShiftRuleController::class, 'adminIndex']);
        Route::post('/departments', [AdminDepartmentController::class, 'store']);
        Route::put('/departments/{department}', [AdminDepartmentController::class, 'update']);
        Route::get('/attendance-overview', [AdminAttendanceController::class, 'overview']);
        Route::get('/monthly-attendance', [AdminAttendanceController::class, 'monthlyOverview']);
        Route::get('/monthly-attendance/export', [AdminAttendanceController::class, 'exportMonthlyCsv']);
        Route::get('/payroll', [AdminPayrollController::class, 'overview']);
        Route::get('/payroll/export', [AdminPayrollController::class, 'exportCsv']);

        Route::get('/users', [AdminUserController::class, 'index']);
        Route::post('/users', [AdminUserController::class, 'store']);
        Route::get('/users/{user}', [AdminUserController::class, 'show']);
        Route::put('/users/{user}', [AdminUserController::class, 'update']);
        Route::delete('/users/{user}', [AdminUserController::class, 'destroy']);
    });
});
