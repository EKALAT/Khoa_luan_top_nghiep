<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('shift_rules', function (Blueprint $table) {
            $table->id();
            $table->string('name', 100);

            $table->time('morning_check_in_start');
            $table->time('morning_check_in_end');

            $table->time('morning_check_out_start');
            $table->time('morning_check_out_end');

            $table->time('afternoon_check_in_start');
            $table->time('afternoon_check_in_end');

            $table->time('afternoon_check_out_start');
            $table->time('afternoon_check_out_end');

            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('shift_rules');
    }
};