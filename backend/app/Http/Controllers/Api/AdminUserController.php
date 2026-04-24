<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Role;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminUserController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'role_code' => ['nullable', 'string', 'max:50'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $users = User::query()
            ->with(['role', 'department'])
            ->when($filters['search'] ?? null, function ($query, $search) {
                $query->where(function ($innerQuery) use ($search) {
                    $innerQuery
                        ->where('employee_code', 'like', '%' . $search . '%')
                        ->orWhere('name', 'like', '%' . $search . '%')
                        ->orWhere('email', 'like', '%' . $search . '%')
                        ->orWhere('phone', 'like', '%' . $search . '%');
                });
            })
            ->when(
                $filters['role_code'] ?? null,
                fn ($query, $roleCode) => $query->whereHas('role', fn ($roleQuery) => $roleQuery->where('code', $roleCode))
            )
            ->when(
                array_key_exists('is_active', $filters),
                fn ($query) => $query->where('is_active', (bool) $filters['is_active'])
            )
            ->orderBy('name')
            ->paginate(12)
            ->through(fn (User $user) => $this->transformUser($request, $user))
            ->appends($request->query());

        return response()->json($users);
    }

    public function show(Request $request, User $user): JsonResponse
    {
        $user->load(['role', 'department']);

        return response()->json([
            'data' => $this->transformUser($request, $user),
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'role_id' => ['required', 'integer', 'exists:roles,id'],
            'department_id' => ['nullable', 'integer', 'exists:departments,id'],
            'employee_code' => ['required', 'string', 'max:50', Rule::unique('users', 'employee_code')],
            'name' => ['required', 'string', 'max:100'],
            'email' => ['nullable', 'email', 'max:100', Rule::unique('users', 'email')],
            'phone' => ['nullable', 'string', 'max:20'],
            'password' => ['required', 'string', 'min:8'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $user = User::create([
            ...$validated,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        $user->load(['role', 'department']);

        return response()->json([
            'message' => 'Tạo tài khoản thành công.',
            'data' => $this->transformUser($request, $user),
        ], 201);
    }

    public function update(Request $request, User $user): JsonResponse
    {
        $validated = $request->validate([
            'role_id' => ['sometimes', 'required', 'integer', 'exists:roles,id'],
            'department_id' => ['sometimes', 'nullable', 'integer', 'exists:departments,id'],
            'employee_code' => ['sometimes', 'required', 'string', 'max:50', Rule::unique('users', 'employee_code')->ignore($user->id)],
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'email' => ['sometimes', 'nullable', 'email', 'max:100', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['sometimes', 'nullable', 'string', 'max:20'],
            'password' => ['nullable', 'string', 'min:8'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $currentUser = $request->user();

        if ($currentUser && $currentUser->id === $user->id) {
            if (array_key_exists('is_active', $validated) && ! $validated['is_active']) {
                return response()->json([
                    'message' => 'Bạn không thể tự khóa tài khoản của mình.',
                ], 422);
            }

            if (array_key_exists('role_id', $validated)) {
                $targetRole = Role::query()->find($validated['role_id']);

                if (! $targetRole || $targetRole->code !== 'admin') {
                    return response()->json([
                        'message' => 'Bạn không thể tự bỏ quyền admin của mình.',
                    ], 422);
                }
            }
        }

        if (array_key_exists('password', $validated) && blank($validated['password'])) {
            unset($validated['password']);
        }

        $user->update($validated);
        $user->refresh()->load(['role', 'department']);

        return response()->json([
            'message' => 'Cập nhật tài khoản thành công.',
            'data' => $this->transformUser($request, $user),
        ]);
    }

    public function destroy(Request $request, User $user): JsonResponse
    {
        $currentUser = $request->user();

        if ($currentUser && $currentUser->id === $user->id) {
            return response()->json([
                'message' => 'Bạn không thể xóa tài khoản hiện tại của mình.',
            ], 422);
        }

        $user->delete();

        return response()->json([
            'message' => 'Xóa tài khoản thành công.',
        ]);
    }

    private function transformUser(Request $request, User $user): array
    {
        $user->loadMissing(['role', 'department']);

        return [
            'id' => $user->id,
            'employee_code' => $user->employee_code,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_path' => $user->avatar_path,
            'avatar_url' => $this->resolveAvatarUrl($request, $user->avatar_path),
            'role_id' => $user->role_id,
            'role' => $user->role?->name,
            'role_code' => $user->role?->code,
            'department_id' => $user->department_id,
            'department' => $user->department?->name,
            'department_code' => $user->department?->code,
            'is_active' => $user->is_active,
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
