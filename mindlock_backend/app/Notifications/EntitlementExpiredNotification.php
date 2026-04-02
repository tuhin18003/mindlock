<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class EntitlementExpiredNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function via(object $notifiable): array
    {
        return ['mail', 'database'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Your MindLock Pro access has expired')
            ->greeting("Hi {$notifiable->name},")
            ->line('Your MindLock Pro subscription has expired.')
            ->line('You have been moved to the free plan. Your data is safe — renew to regain full access.')
            ->action('Renew Pro', url('/subscription'))
            ->line('Thank you for using MindLock!');
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type'    => 'entitlement_expired',
            'message' => 'Your Pro access has expired. Renew to regain full access.',
        ];
    }
}
