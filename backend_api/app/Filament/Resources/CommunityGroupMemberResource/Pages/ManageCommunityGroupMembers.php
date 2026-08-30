<?php

namespace App\Filament\Resources\CommunityGroupMemberResource\Pages;

use App\Filament\Resources\CommunityGroupMemberResource;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ManageRecords;

class ManageCommunityGroupMembers extends ManageRecords
{
    protected static string $resource = CommunityGroupMemberResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }
}