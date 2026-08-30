<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CommunityGroup extends Model
{
    use HasFactory;

    protected $fillable = [
        'name_ar',
        'slug',
        'description_ar',
        'icon',
        'color',
        'visibility',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    public function members(): HasMany
    {
        return $this->hasMany(CommunityGroupMember::class, 'community_group_id');
    }

    public function posts(): HasMany
    {
        return $this->hasMany(CommunityPost::class, 'community_group_id');
    }
}