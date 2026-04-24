<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Department;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminDepartmentController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'code' => ['required', 'string', 'max:50', Rule::unique('departments', 'code')],
            'description' => ['nullable', 'string', 'max:255'],
            'monthly_salary' => ['nullable', 'numeric', 'min:0', 'max:9999999999.99'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $department = Department::create([
            'name' => trim($validated['name']),
            'code' => trim($validated['code']),
            'description' => $validated['description'] ?? null,
            'monthly_salary' => round((float) ($validated['monthly_salary'] ?? 0), 2),
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'message' => 'Tao phong ban thanh cong.',
            'data' => $this->transformDepartment($department),
        ], 201);
    }

    public function update(Request $request, Department $department): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'code' => ['sometimes', 'required', 'string', 'max:50', Rule::unique('departments', 'code')->ignore($department->id)],
            'description' => ['sometimes', 'nullable', 'string', 'max:255'],
            'monthly_salary' => ['sometimes', 'required', 'numeric', 'min:0', 'max:9999999999.99'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $payload = [];

        if (array_key_exists('name', $validated)) {
            $payload['name'] = trim($validated['name']);
        }

        if (array_key_exists('code', $validated)) {
            $payload['code'] = trim($validated['code']);
        }

        if (array_key_exists('description', $validated)) {
            $payload['description'] = $validated['description'];
        }

        if (array_key_exists('monthly_salary', $validated)) {
            $payload['monthly_salary'] = round((float) $validated['monthly_salary'], 2);
        }

        if (array_key_exists('is_active', $validated)) {
            $payload['is_active'] = (bool) $validated['is_active'];
        }

        $department->update($payload);

        return response()->json([
            'message' => 'Cap nhat phong ban thanh cong.',
            'data' => $this->transformDepartment($department),
        ]);
    }

    private function transformDepartment(Department $department): array
    {
        return [
            'id' => $department->id,
            'name' => $department->name,
            'code' => $department->code,
            'description' => $department->description,
            'monthly_salary' => (float) $department->monthly_salary,
            'is_active' => (bool) $department->is_active,
        ];
    }
}
