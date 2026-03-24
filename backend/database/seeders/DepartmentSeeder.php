<?php

namespace Database\Seeders;

use App\Models\Department;
use Illuminate\Database\Seeder;

class DepartmentSeeder extends Seeder
{
    public function run(): void
    {
        Department::updateOrCreate(
            ['code' => 'it'],
            [
                'name' => 'IT',
                'description' => 'IT Department',
                'is_active' => true,
            ]
        );

        Department::updateOrCreate(
            ['code' => 'hr'],
            [
                'name' => 'HR',
                'description' => 'HR Department',
                'is_active' => true,
            ]
        );
    }
}