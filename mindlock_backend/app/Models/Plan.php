<?php
namespace App\Models;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Plan extends Model {
    protected $fillable = ['slug','name','description','tier','billing_cycle','price','currency','store_product_id','is_active','trial_days','features','sort_order'];
    protected $casts = ['features' => 'array', 'is_active' => 'boolean'];
    public function entitlements(): HasMany { return $this->hasMany(Entitlement::class); }
}
