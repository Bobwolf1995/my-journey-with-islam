<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Profile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'current_level_id',
        'display_name',
        'avatar',
        'bio',
        'country',
        'city',
        'language',
        'points',
        'streak_days',
        'last_activity_date',
        'preferences',
    ];

    protected function casts(): array
    {
        return [
            'points' => 'integer',
            'streak_days' => 'integer',
            'last_activity_date' => 'date',
            'preferences' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function level(): BelongsTo
    {
        return $this->belongsTo(Level::class, 'current_level_id');
    }
}