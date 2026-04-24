<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WorkLocation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WorkLocationController extends Controller
{
    public function index(): JsonResponse
    {
        $locations = WorkLocation::query()
            ->where('is_active', true)
            ->orderBy('id')
            ->get();

        return response()->json([
            'data' => $locations,
        ]);
    }

    public function adminIndex(): JsonResponse
    {
        $locations = WorkLocation::query()
            ->orderByDesc('is_active')
            ->orderBy('id')
            ->get();

        return response()->json([
            'data' => $locations,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:150'],
            'address' => ['nullable', 'string', 'max:255'],
            'latitude' => ['required', 'numeric', 'between:-90,90'],
            'longitude' => ['required', 'numeric', 'between:-180,180'],
            'radius_m' => ['nullable', 'integer', 'min:1', 'max:5000'],
            'allowed_network' => ['nullable', 'string', 'max:255'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $location = WorkLocation::create([
            'name' => $validated['name'],
            'address' => $validated['address'] ?? null,
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude'],
            'radius_m' => $validated['radius_m'] ?? 50,
            'allowed_network' => $validated['allowed_network'] ?? null,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'message' => 'Tao dia diem cong ty thanh cong.',
            'data' => $location,
        ], 201);
    }

    public function show(WorkLocation $workLocation): JsonResponse
    {
        return response()->json([
            'data' => $workLocation,
        ]);
    }

    public function update(Request $request, WorkLocation $workLocation): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:150'],
            'address' => ['nullable', 'string', 'max:255'],
            'latitude' => ['sometimes', 'required', 'numeric', 'between:-90,90'],
            'longitude' => ['sometimes', 'required', 'numeric', 'between:-180,180'],
            'radius_m' => ['nullable', 'integer', 'min:1', 'max:5000'],
            'allowed_network' => ['nullable', 'string', 'max:255'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $workLocation->update($validated);

        return response()->json([
            'message' => 'Cap nhat dia diem cong ty thanh cong.',
            'data' => $workLocation->fresh(),
        ]);
    }

    public function destroy(WorkLocation $workLocation): JsonResponse
    {
        $workLocation->delete();

        return response()->json([
            'message' => 'Xoa dia diem cong ty thanh cong.',
        ]);
    }
}
