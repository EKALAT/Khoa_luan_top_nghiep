<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('attendance_records', function (Blueprint $table) {
            $table->id();

            $table->foreignId('user_id')
                ->constrained('users')
                ->cascadeOnUpdate()
                ->cascadeOnDelete();

            $table->foreignId('work_location_id')
                ->constrained('work_locations')
                ->cascadeOnUpdate()
                ->restrictOnDelete();

            $table->string('check_type', 50);
            $table->string('status', 20)->default('valid');
            $table->date('check_date');
            $table->time('check_time');
            $table->decimal('distance_m', 8, 2)->nullable();
            $table->decimal('accuracy_m', 8, 2)->nullable();
            $table->string('reason', 50)->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'check_date', 'check_type'], 'attendance_unique_user_date_type');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('attendance_records');
    }
};