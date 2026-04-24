<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Department;
use App\Models\Role;
use Illuminate\Http\JsonResponse;

class AdminLookupController extends Controller
{
    public function roles(): JsonResponse
    {
        $roles = Role::query()
            ->orderBy('name')
            ->get(['id', 'name', 'code', 'description']);

        return response()->json([
            'data' => $roles,
        ]);
    }

    public function departments(): JsonResponse
    {
        $departments = Department::query()
            ->orderBy('name')
            ->get(['id', 'name', 'code', 'description', 'monthly_salary', 'is_active']);

        return response()->json([
            'data' => $departments,
        ]);
    }
}
