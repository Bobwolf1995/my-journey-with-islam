<?php

namespace App\Filament\Resources\AiChatLogResource\Pages;

use App\Filament\Resources\AiChatLogResource;
use Filament\Resources\Pages\ManageRecords;

class ManageAiChatLogs extends ManageRecords
{
    protected static string $resource = AiChatLogResource::class;

    protected function getHeaderActions(): array
    {
        return [];
    }
}