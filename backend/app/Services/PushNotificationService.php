<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Contract\Messaging;
use Kreait\Firebase\Messaging\CloudMessage;
use Kreait\Firebase\Messaging\Notification;

class PushNotificationService
{
    /**
     * Send a push notification to a user's registered device, if any.
     *
     * The Firebase Messaging client is resolved lazily (not constructor
     * injected): until FIREBASE_CREDENTIALS is configured, resolving it
     * throws, so doing so eagerly would break every request through a
     * controller that depends on this service. Failures are logged rather
     * than thrown so a missing/invalid Firebase setup never breaks the API
     * request that triggered the notification.
     */
    public function sendToUser(User $user, string $title, string $body, array $data = []): void
    {
        if (empty($user->fcm_token)) {
            return;
        }

        try {
            $message = CloudMessage::withTarget('token', $user->fcm_token)
                ->withNotification(Notification::create($title, $body))
                ->withData(array_map('strval', $data));

            app(Messaging::class)->send($message);
        } catch (\Throwable $e) {
            // Covers messaging failures as well as Firebase not being configured yet.
            Log::warning('Notification push ignorée : '.$e->getMessage(), ['user_id' => $user->id]);
        }
    }
}
