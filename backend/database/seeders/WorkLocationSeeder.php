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
                'allowed_network' => '113.161.12.141',
                'is_active' => true,
            ]
        );

        WorkLocation::updateOrCreate(
            ['name' => 'MIDTrans'],
            [
                'address' => '02 Hoang Dieu, Nam Ly, Dong Hoi, Quang Tri, Vietnam',
                'latitude' => 17.4665500,
                'longitude' => 106.5985400,
                'radius_m' => 50,
                'allowed_network' => '113.161.12.141,2001:ee0:4bbb:a90::/64',
                'is_active' => true,
            ]
        );
    }
}
