<?php

namespace Database\Seeders;

use App\Models\WorkLocation;
use Illuminate\Database\Seeder;

class WorkLocationSeeder extends Seeder
{
    public function run(): void
    {
        WorkLocation::updateOrCreate(
            ['name' => 'Main Office'],
            [
                'address' => 'Company Headquarters',
                'latitude' => 10.7626220,
                'longitude' => 106.6601720,
                'radius_m' => 50,
                'allowed_network' => 'Company WiFi',
                'is_active' => true,
            ]
        );
    }
}