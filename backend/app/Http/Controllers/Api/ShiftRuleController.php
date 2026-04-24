<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ShiftRule;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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

    public function adminIndex(): JsonResponse
    {
        $rules = ShiftRule::query()
            ->orderByDesc('is_active')
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

        $rule = DB::transaction(function () use ($validated) {
            $isActive = $validated['is_active'] ?? true;

            if ($isActive) {
                ShiftRule::query()->update(['is_active' => false]);
            }

            return ShiftRule::create([
                ...$validated,
                'is_active' => $isActive,
            ]);
        });

        return response()->json([
            'message' => 'Tao quy tac ca lam viec thanh cong.',
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

        $rule = DB::transaction(function () use ($validated, $shiftRule) {
            if (($validated['is_active'] ?? null) === true) {
                ShiftRule::query()
                    ->whereKeyNot($shiftRule->id)
                    ->update(['is_active' => false]);
            }

            $shiftRule->update($validated);

            return $shiftRule->fresh();
        });

        return response()->json([
            'message' => 'Cap nhat quy tac ca lam viec thanh cong.',
            'data' => $rule,
        ]);
    }

    public function destroy(ShiftRule $shiftRule): JsonResponse
    {
        $shiftRule->delete();

        return response()->json([
            'message' => 'Xoa quy tac ca lam viec thanh cong.',
        ]);
    }
}
