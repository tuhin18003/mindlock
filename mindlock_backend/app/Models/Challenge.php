<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Challenge extends Model {
    protected $fillable = [
        'category_id','slug','title','description','type','content',
        'difficulty','reward_minutes','estimated_seconds','is_pro',
        'is_active','goal','cooldown_minutes','effectiveness_score',
        'completion_count','skip_count','sort_order'
    ];
    protected $casts = ['is_pro' => 'boolean','is_active' => 'boolean'];
    public function category(): BelongsTo { return $this->belongsTo(ChallengeCategory::class); }
    public function completions(): HasMany { return $this->hasMany(ChallengeCompletion::class); }
}
