<?php

namespace App\Filament\Resources\ConversationParticipantResource\Pages;

use App\Filament\Resources\ConversationParticipantResource;
use Filament\Resources\Pages\ManageRecords;

class ManageConversationParticipants extends ManageRecords
{
    protected static string $resource = ConversationParticipantResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}