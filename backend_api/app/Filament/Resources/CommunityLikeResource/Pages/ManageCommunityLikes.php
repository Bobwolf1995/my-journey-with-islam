<?php

namespace App\Filament\Resources\CommunityLikeResource\Pages;

use App\Filament\Resources\CommunityLikeResource;
use Filament\Resources\Pages\ManageRecords;

class ManageCommunityLikes extends ManageRecords
{
    protected static string $resource = CommunityLikeResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}