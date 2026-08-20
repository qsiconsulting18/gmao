<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('tenant_id')->nullable()->after('id')->constrained()->nullOnDelete();
            $table->enum('role', ['admin', 'manager', 'technician', 'operator'])->default('technician')->after('email');
            $table->string('phone')->nullable()->after('role');
            $table->text('fcm_token')->nullable()->after('phone');
            $table->boolean('is_active')->default(true)->after('fcm_token');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('tenant_id');
            $table->dropColumn(['role', 'phone', 'fcm_token', 'is_active']);
        });
    }
};
