<?php

namespace App\Filament\Resources\CommunityGroupResource\Pages;

use App\Filament\Resources\CommunityGroupResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageCommunityGroups extends ManageRecords
{
    protected static string $resource = CommunityGroupResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}
