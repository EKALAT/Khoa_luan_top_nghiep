<?php

namespace Database\Seeders;

use App\Models\ShiftRule;
use Illuminate\Database\Seeder;

class ShiftRuleSeeder extends Seeder
{
    public function run(): void
    {
        ShiftRule::updateOrCreate(
            ['name' => 'Default Shift'],
            [
                'morning_check_in_start' => '07:40:00',
                'morning_check_in_end' => '08:20:00',
                'morning_check_out_start' => '11:20:00',
                'morning_check_out_end' => '11:40:00',
                'afternoon_check_in_start' => '13:10:00',
                'afternoon_check_in_end' => '13:30:00',
                'afternoon_check_out_start' => '16:40:00',
                'afternoon_check_out_end' => '17:30:00',
                'is_active' => true,
            ]
        );
    }
}