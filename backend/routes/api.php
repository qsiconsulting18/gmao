<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\EquipmentController;
use App\Http\Controllers\Api\InterventionController;
use App\Http\Controllers\Api\PartController;
use App\Http\Controllers\Api\PreventivePlanController;
use App\Http\Controllers\Api\TicketController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\WorkOrderController;
use Illuminate\Support\Facades\Route;

Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::post('/auth/fcm-token', [AuthController::class, 'updateFcmToken']);

    // Equipements — lecture ouverte à tous les rôles authentifiés (scan terrain compris)
    Route::get('/equipments', [EquipmentController::class, 'index']);
    Route::get('/equipments/qr/{token}', [EquipmentController::class, 'showByQrToken']);
    Route::get('/equipments/{equipment}', [EquipmentController::class, 'show']);
    Route::get('/equipments/{equipment}/qr-code', [EquipmentController::class, 'qrCode']);

    // Tickets — signalement ouvert à tous, consultation ouverte
    Route::get('/tickets', [TicketController::class, 'index']);
    Route::post('/tickets', [TicketController::class, 'store']);
    Route::get('/tickets/{ticket}', [TicketController::class, 'show']);

    // Interventions — clôture terrain (technicien, manager, admin)
    Route::middleware('role:technician,manager,admin')->group(function () {
        Route::get('/interventions', [InterventionController::class, 'index']);
        Route::post('/interventions', [InterventionController::class, 'store']);
        Route::get('/interventions/{intervention}', [InterventionController::class, 'show']);
        Route::patch('/tickets/{ticket}', [TicketController::class, 'update']);
    });

    // Bons de travail — lecture pour tous, écriture pour manager/admin
    Route::get('/work-orders', [WorkOrderController::class, 'index']);
    Route::get('/work-orders/{workOrder}', [WorkOrderController::class, 'show']);
    Route::middleware('role:technician,manager,admin')->patch('/work-orders/{workOrder}', [WorkOrderController::class, 'update']);

    // Pièces détachées — lecture pour tous (sélection lors d'une intervention terrain)
    Route::get('/parts', [PartController::class, 'index']);
    Route::get('/parts/{part}', [PartController::class, 'show']);

    // Pilotage — manager & admin uniquement
    Route::middleware('role:manager,admin')->group(function () {
        Route::post('/equipments', [EquipmentController::class, 'store']);
        Route::put('/equipments/{equipment}', [EquipmentController::class, 'update']);
        Route::patch('/equipments/{equipment}', [EquipmentController::class, 'update']);
        Route::delete('/equipments/{equipment}', [EquipmentController::class, 'destroy']);
        Route::get('/equipments-export', [EquipmentController::class, 'exportExcel']);
        Route::post('/equipments-import', [EquipmentController::class, 'importExcel']);

        Route::patch('/tickets/{ticket}/assign', [TicketController::class, 'assign']);

        Route::apiResource('preventive-plans', PreventivePlanController::class)->except(['index', 'show']);
        Route::get('/preventive-plans', [PreventivePlanController::class, 'index']);
        Route::get('/preventive-plans/{preventivePlan}', [PreventivePlanController::class, 'show']);

        Route::post('/work-orders', [WorkOrderController::class, 'store']);

        Route::post('/parts', [PartController::class, 'store']);
        Route::match(['put', 'patch'], '/parts/{part}', [PartController::class, 'update']);
        Route::post('/parts/{part}/restock', [PartController::class, 'restock']);

        Route::apiResource('users', UserController::class)->except(['show']);

        Route::get('/dashboard', [DashboardController::class, 'index']);
    });
});
