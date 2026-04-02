<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class StreakBrokenNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        private readonly int $streakLost,
    ) {}

    public function via(object $notifiable): array
    {
        $prefs = $notifiable->notificationPreferences;

        $channels = ['database'];

        if ($prefs?->email_enabled && $prefs?->streak_alerts) {
            $channels[] = 'mail';
        }

        return $channels;
    }

    public function toMail(object $notifiable): MailMessage
    {
        return (new MailMessage)
            ->subject('Your MindLock streak has been broken')
            ->greeting("Hi {$notifiable->name},")
            ->line("Your {$this->streakLost}-day streak was broken. It happens — what matters is getting back on track today.")
            ->line('Open MindLock to start rebuilding your discipline streak.')
            ->action('Open MindLock', url('/'))
            ->line('You got this!');
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type'       => 'streak_broken',
            'streak_lost' => $this->streakLost,
            'message'    => "Your {$this->streakLost}-day streak was broken. Start fresh today!",
        ];
    }
}
