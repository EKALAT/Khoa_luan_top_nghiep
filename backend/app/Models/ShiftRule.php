<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ShiftRule extends Model
{
    protected $fillable = [
        'name',
        'morning_check_in_start',
        'morning_check_in_end',
        'morning_check_out_start',
        'morning_check_out_end',
        'afternoon_check_in_start',
        'afternoon_check_in_end',
        'afternoon_check_out_start',
        'afternoon_check_out_end',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }
}