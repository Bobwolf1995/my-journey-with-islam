<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Task extends Model
{
    use HasFactory;

    protected $fillable = [
        'title_ar',
        'description_ar',
        'type',
        'points',
        'order',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'points' => 'integer',
            'order' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    public function userTasks(): HasMany
    {
        return $this->hasMany(UserTask::class);
    }
}