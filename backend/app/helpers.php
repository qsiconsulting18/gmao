<?php

use Illuminate\Support\Facades\Auth;

if (! function_exists('tenant_id')) {
    /**
     * Resolve the current tenant id from the authenticated user.
     * Returns null outside of an authenticated request (console, seeders),
     * in which case tenant-scoped queries are left unscoped.
     */
    function tenant_id(): ?int
    {
        return Auth::check() ? Auth::user()->tenant_id : null;
    }
}
