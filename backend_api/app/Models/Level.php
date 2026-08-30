<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Level extends Model
{
    use HasFactory;

    protected $fillable = [
        'name_ar',
        'slug',
        'description_ar',
        'order',
        'required_points',
        'icon',
        'color',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'order' => 'integer',
            'required_points' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    public function profiles(): HasMany
    {
        return $this->hasMany(Profile::class, 'current_level_id');
    }
}