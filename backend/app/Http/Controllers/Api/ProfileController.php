<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\UploadedFile;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $user = $request->user();

        return response()->json([
            'data' => $this->transformUserProfile($request, $user),
        ]);
    }

    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'email' => ['nullable', 'email', 'max:100', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['nullable', 'string', 'max:20'],
        ]);

        $user->update($validated);
        $user->refresh();

        return response()->json([
            'message' => 'Cập nhật hồ sơ thành công.',
            'data' => $this->transformUserProfile($request, $user),
        ]);
    }

    public function uploadAvatar(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'avatar' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048'],
        ]);

        $newAvatarPath = $this->storeAvatar(
            $validated['avatar'],
            $user->employee_code,
        );

        $oldAvatarPath = $user->avatar_path;
        $user->update([
            'avatar_path' => $newAvatarPath,
        ]);

        if ($oldAvatarPath && $oldAvatarPath !== $newAvatarPath) {
            Storage::disk('public')->delete($oldAvatarPath);
        }

        $user->refresh();

        return response()->json([
            'message' => 'Cập nhật ảnh đại diện thành công.',
            'data' => $this->transformUserProfile($request, $user),
        ]);
    }

    public function avatar(string $filename)
    {
        $safeFilename = basename($filename);
        $path = 'avatars/' . $safeFilename;

        abort_unless(Storage::disk('public')->exists($path), 404);

        return Storage::disk('public')->response($path, $safeFilename);
    }

    private function transformUserProfile(Request $request, $user): array
    {
        return [
            'id' => $user->id,
            'employee_code' => $user->employee_code,
            'name' => $user->name,
            'email' => $user->email,
            'phone' => $user->phone,
            'avatar_path' => $user->avatar_path,
            'avatar_url' => $this->resolveAvatarUrl($request, $user->avatar_path),
        ];
    }

    private function resolveAvatarUrl(Request $request, ?string $avatarPath): ?string
    {
        if (! $avatarPath) {
            return null;
        }

        return rtrim($request->root(), '/') . '/api/avatars/' . rawurlencode(basename($avatarPath));
    }

    private function storeAvatar(UploadedFile $avatar, string $employeeCode): string
    {
        $filename = Str::slug($employeeCode) . '-' . Str::uuid() . '.' . $avatar->getClientOriginalExtension();

        return $avatar->storeAs('avatars', $filename, 'public');
    }
}
