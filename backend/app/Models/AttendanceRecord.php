<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AttendanceRecord extends Model
{
    protected $fillable = [
        'user_id',
        'work_location_id',
        'check_type',
        'status',
        'check_date',
        'check_time',
        'distance_m',
        'accuracy_m',
        'reason',
    ];

    protected function casts(): array
    {
        return [
            'check_date' => 'date',
            'distance_m' => 'decimal:2',
            'accuracy_m' => 'decimal:2',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function workLocation(): BelongsTo
    {
        return $this->belongsTo(WorkLocation::class);
    }

    public function logs(): HasMany
    {
        return $this->hasMany(AttendanceLog::class);
    }
}