<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AuthController extends Controller
{
    public function login(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'employee_code' => ['required', 'string'],
            'password' => ['required', 'string'],
        ]);

        $user = User::with(['role', 'department'])
            ->where('employee_code', $validated['employee_code'])
            ->first();

        if (! $user || ! Hash::check($validated['password'], $user->password)) {
            return response()->json([
                'message' => 'Thông tin đăng nhập không đúng.',
            ], 401);
        }

        if (! $user->is_active) {
            return response()->json([
                'message' => 'Tài khoản đã bị khóa.',
            ], 403);
        }

        $token = $user->createToken('mobile-token')->plainTextToken;

        $user->update([
            'last_login_at' => now(),
        ]);

        return response()->json([
            'message' => 'Đăng nhập thành công.',
            'token' => $token,
            'token_type' => 'Bearer',
            'user' => [
                'id' => $user->id,
                'employee_code' => $user->employee_code,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role?->name,
                'department' => $user->department?->name,
            ],
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user()->load(['role', 'department']);

        return response()->json([
            'user' => [
                'id' => $user->id,
                'employee_code' => $user->employee_code,
                'name' => $user->name,
                'email' => $user->email,
                'phone' => $user->phone,
                'role' => $user->role?->name,
                'department' => $user->department?->name,
                'last_login_at' => $user->last_login_at,
            ],
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Đăng xuất thành công.',
        ]);
    }
}