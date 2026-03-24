<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ShiftRule;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ShiftRuleController extends Controller
{
    public function index(): JsonResponse
    {
        $rules = ShiftRule::query()
            ->where('is_active', true)
            ->orderBy('id')
            ->get();

        return response()->json([
            'data' => $rules,
        ]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'morning_check_in_start' => ['required', 'date_format:H:i:s'],
            'morning_check_in_end' => ['required', 'date_format:H:i:s'],
            'morning_check_out_start' => ['required', 'date_format:H:i:s'],
            'morning_check_out_end' => ['required', 'date_format:H:i:s'],
            'afternoon_check_in_start' => ['required', 'date_format:H:i:s'],
            'afternoon_check_in_end' => ['required', 'date_format:H:i:s'],
            'afternoon_check_out_start' => ['required', 'date_format:H:i:s'],
            'afternoon_check_out_end' => ['required', 'date_format:H:i:s'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $rule = ShiftRule::create([
            ...$validated,
            'is_active' => $validated['is_active'] ?? true,
        ]);

        return response()->json([
            'message' => 'Tạo quy tắc ca làm việc thành công.',
            'data' => $rule,
        ], 201);
    }

    public function show(ShiftRule $shiftRule): JsonResponse
    {
        return response()->json([
            'data' => $shiftRule,
        ]);
    }

    public function update(Request $request, ShiftRule $shiftRule): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:100'],
            'morning_check_in_start' => ['sometimes', 'required', 'date_format:H:i:s'],
            'morning_check_in_end' => ['sometimes', 'required', 'date_format:H:i:s'],
            'morning_check_out_start' => ['sometimes', 'required', 'date_format:H:i:s'],
            'morning_check_out_end' => ['sometimes', 'required', 'date_format:H:i:s'],
            'afternoon_check_in_start' => ['sometimes', 'required', 'date_format:H:i:s'],
            'afternoon_check_in_end' => ['sometimes', 'required', 'date_format:H:i:s'],
            'afternoon_check_out_start' => ['sometimes', 'required', 'date_format:H:i:s'],
            'afternoon_check_out_end' => ['sometimes', 'required', 'date_format:H:i:s'],
            'is_active' => ['nullable', 'boolean'],
        ]);

        $shiftRule->update($validated);

        return response()->json([
            'message' => 'Cập nhật quy tắc ca làm việc thành công.',
            'data' => $shiftRule->fresh(),
        ]);
    }

    public function destroy(ShiftRule $shiftRule): JsonResponse
    {
        $shiftRule->delete();

        return response()->json([
            'message' => 'Xóa quy tắc ca làm việc thành công.',
        ]);
    }
}