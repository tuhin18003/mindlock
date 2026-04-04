<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class ChallengeCategory extends Model {
    protected $guarded = ['id'];

    public function challenges(): HasMany
    {
        return $this->hasMany(Challenge::class, 'category_id');
    }
}
