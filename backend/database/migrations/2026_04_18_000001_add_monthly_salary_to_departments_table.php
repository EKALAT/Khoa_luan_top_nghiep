<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasColumn('departments', 'monthly_salary')) {
            return;
        }

        Schema::table('departments', function (Blueprint $table) {
            $table->decimal('monthly_salary', 12, 2)->default(0)->after('description');
        });
    }

    public function down(): void
    {
        if (! Schema::hasColumn('departments', 'monthly_salary')) {
            return;
        }

        Schema::table('departments', function (Blueprint $table) {
            $table->dropColumn('monthly_salary');
        });
    }
};
