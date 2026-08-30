<?php

namespace App\Filament\Resources\CommunityCommentResource\Pages;

use App\Filament\Resources\CommunityCommentResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageCommunityComments extends ManageRecords
{
    protected static string $resource = CommunityCommentResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}