<?php

namespace Database\Seeders;

use App\Models\Department;
use App\Models\Role;
use App\Models\User;
use Illuminate\Database\Seeder;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        $adminRole = Role::where('code', 'admin')->firstOrFail();
        $employeeRole = Role::where('code', 'employee')->firstOrFail();
        $itDepartment = Department::where('code', 'it')->firstOrFail();

        User::updateOrCreate(
            ['employee_code' => 'admin01'],
            [
                'role_id' => $adminRole->id,
                'department_id' => $itDepartment->id,
                'name' => 'System Admin',
                'email' => 'admin@example.com',
                'phone' => '0900000001',
                'password' => 'password123',
                'is_active' => true,
            ]
        );

        User::updateOrCreate(
            ['employee_code' => 'nv001'],
            [
                'role_id' => $employeeRole->id,
                'department_id' => $itDepartment->id,
                'name' => 'Nguyen Van A',
                'email' => 'nv001@example.com',
                'phone' => '0900000002',
                'password' => 'password123',
                'is_active' => true,
            ]
        );
    }
}
