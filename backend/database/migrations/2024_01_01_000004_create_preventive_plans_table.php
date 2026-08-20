<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('preventive_plans', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('equipment_id')->constrained('equipments')->cascadeOnDelete();
            $table->string('name');
            $table->enum('frequency_type', ['days', 'weeks', 'months'])->default('months');
            $table->unsignedInteger('frequency_value')->default(1);
            $table->date('next_due_date');
            $table->boolean('active')->default(true);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();

            $table->index(['tenant_id', 'active', 'next_due_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('preventive_plans');
    }
};
