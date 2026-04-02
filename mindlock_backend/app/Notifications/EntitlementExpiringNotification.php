<?php

namespace App\Notifications;

use App\Models\Entitlement;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class EntitlementExpiringNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        private readonly Entitlement $entitlement,
        private readonly int $daysRemaining,
    ) {}

    public function via(object $notifiable): array
    {
        return ['mail', 'database'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject("Your MindLock Pro access expires in {$this->daysRemaining} day(s)")
            ->greeting("Hi {$notifiable->name},")
            ->line("Your MindLock Pro subscription expires in **{$this->daysRemaining} day(s)**.")
            ->line('Renew now to keep your streaks, advanced challenges, and unlimited app limits.')
            ->action('Manage Subscription', url('/subscription'))
            ->line('Thank you for using MindLock!');
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type'           => 'entitlement_expiring',
            'days_remaining' => $this->daysRemaining,
            'expires_at'     => $this->entitlement->expires_at?->toIso8601String(),
            'message'        => "Your Pro access expires in {$this->daysRemaining} day(s).",
        ];
    }
}
