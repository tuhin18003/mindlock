<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class WeeklyReportNotification extends Notification implements ShouldQueue
{
    use Queueable;

    public function __construct(
        private readonly array $summary,
    ) {}

    public function via(object $notifiable): array
    {
        $prefs = $notifiable->notificationPreferences;

        $channels = ['database'];

        if ($prefs?->email_enabled && $prefs?->weekly_report) {
            $channels[] = 'mail';
        }

        return $channels;
    }

    public function toMail(object $notifiable): MailMessage
    {
        $score        = $this->summary['recovery_score'] ?? 0;
        $locks        = $this->summary['total_locks'] ?? 0;
        $challenges   = $this->summary['challenges_completed'] ?? 0;
        $focusMinutes = $this->summary['focus_minutes'] ?? 0;
        $streak       = $this->summary['current_streak'] ?? 0;

        return (new MailMessage)
            ->subject('Your MindLock Weekly Report')
            ->greeting("Hi {$notifiable->name},")
            ->line("Here's your digital discipline recap for this week:")
            ->line("**Recovery Score:** {$score}/100")
            ->line("**App Locks:** {$locks}")
            ->line("**Challenges Completed:** {$challenges}")
            ->line("**Focus Minutes:** {$focusMinutes}")
            ->line("**Current Streak:** {$streak} days")
            ->action('View Full Report', url('/history'))
            ->line('Keep up the great work!');
    }

    public function toArray(object $notifiable): array
    {
        return [
            'type'    => 'weekly_report',
            'summary' => $this->summary,
            'message' => "Your weekly report is ready. Recovery score: {$this->summary['recovery_score']}/100.",
        ];
    }
}
