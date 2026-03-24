<?php

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Seeder;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        Role::updateOrCreate(
            ['code' => 'admin'],
            ['name' => 'Admin', 'description' => 'Administrator']
        );

        Role::updateOrCreate(
            ['code' => 'employee'],
            ['name' => 'Employee', 'description' => 'Employee']
        );
    }
}