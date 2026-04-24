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

        $user = User::query()
            ->with(['role', 'department'])
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
            'user' => $this->transformUser($request, $user),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'message' => 'Unauthenticated.',
            ], 401);
        }

        $user->load(['role', 'department']);

        return response()->json([
            'user' => $this->transformUser($request, $user),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();

        if (! $user) {
            return response()->json([
                'message' => 'Unauthenticated.',
            ], 401);
        }

        $token = $user->currentAccessToken();

        if ($token) {
            $token->delete();
        }

        return response()->json([
            'message' => 'Đăng xuất thành công.',
        ]);
    }

    private function transformUser(Request $request, User $user): array
    {
        return [
            'id' => $user->id,
            'employee_code' => $user->employee_code,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_path' => $user->avatar_path,
            'avatar_url' => $this->resolveAvatarUrl($request, $user->avatar_path),
            'role' => $user->role?->name,
            'role_code' => $user->role?->code,
            'department' => $user->department?->name,
            'last_login_at' => $user->last_login_at,
        ];
    }

    private function resolveAvatarUrl(Request $request, ?string $avatarPath): ?string
    {
        if (! $avatarPath) {
            return null;
        }

        return rtrim($request->root(), '/') . '/api/avatars/' . rawurlencode(basename($avatarPath));
    }
}
